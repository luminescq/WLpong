use std::time::{Duration, Instant};
use std::collections::HashMap;
use std::sync::{Mutex, OnceLock};
use tokio::net::TcpStream;
use tokio::time::timeout;
use hickory_resolver::TokioAsyncResolver;
use hickory_resolver::config::{ResolverConfig, ResolverOpts};

// ─── Кэш резолверов ──────────────────────────────────────────────────────────

static GLOBAL_RESOLVER: OnceLock<TokioAsyncResolver> = OnceLock::new();
static CUSTOM_RESOLVERS: OnceLock<Mutex<HashMap<String, TokioAsyncResolver>>> = OnceLock::new();

pub fn get_resolver(custom_dns: Option<String>) -> TokioAsyncResolver {
    if let Some(ref dns) = custom_dns {
        if let Ok(ip_addr) = dns.parse::<std::net::IpAddr>() {
            let cache = CUSTOM_RESOLVERS.get_or_init(|| Mutex::new(HashMap::new()));
            let mut map = cache.lock().unwrap();
            return map.entry(dns.clone()).or_insert_with(|| {
                use hickory_resolver::config::{NameServerConfig, Protocol};
                use std::net::SocketAddr;
                let mut config = ResolverConfig::new();
                config.add_name_server(NameServerConfig::new(
                    SocketAddr::new(ip_addr, 53),
                    Protocol::Udp,
                ));
                TokioAsyncResolver::tokio(config, ResolverOpts::default())
            }).clone();
        }
    }
    
    // Default: Google DNS
    GLOBAL_RESOLVER.get_or_init(|| {
        TokioAsyncResolver::tokio(
            ResolverConfig::google(),
            ResolverOpts::default(),
        )
    }).clone()
}

// ─── Типы ошибок ──────────────────────────────────────────────────────────────

/// Типы ошибок пинга (полезно для отладки DPI и блокировок)
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PingErrorKind {
    DnsTimeout,
    DnsFailed,
    DnsNoRecord,
    TcpTimeout,
    TcpRefused,    // Часто означает RST от ТСПУ/DPI
    TcpReset,
    Unknown,
}

/// Результат пинга
#[derive(Debug, Clone)]
pub struct PingResult {
    pub success: bool,
    pub total_time_ms: Option<u32>,
    pub dns_time_ms: Option<u32>,
    pub tcp_time_ms: Option<u32>,
    pub error: Option<PingErrorKind>,
}

// ─── DNS-резолв (отдельно) ────────────────────────────────────────────────────

/// Результат DNS-резолва для кэширования
#[derive(Debug, Clone)]
pub struct DnsEntry {
    pub ip: Option<std::net::IpAddr>,
    pub dns_time_ms: u32,
    pub error: Option<PingErrorKind>,
}

/// Резолвит домен в IP-адрес (отдельно от TCP, для батчевого использования)
pub async fn resolve_dns(
    resolver: &TokioAsyncResolver,
    domain: &str,
    timeout_ms: u64,
) -> DnsEntry {
    let timeout_duration = Duration::from_millis(timeout_ms);
    let start = Instant::now();

    match timeout(timeout_duration, resolver.lookup_ip(domain)).await {
        Ok(Ok(response)) => {
            let dns_time = start.elapsed().as_millis() as u32;
            match response.iter().find(|ip| ip.is_ipv4()) {
                Some(ip) => DnsEntry { ip: Some(ip), dns_time_ms: dns_time, error: None },
                None => DnsEntry { ip: None, dns_time_ms: dns_time, error: Some(PingErrorKind::DnsNoRecord) },
            }
        }
        Ok(Err(_)) => {
            let dns_time = start.elapsed().as_millis() as u32;
            DnsEntry { ip: None, dns_time_ms: dns_time, error: Some(PingErrorKind::DnsFailed) }
        }
        Err(_) => {
            let dns_time = start.elapsed().as_millis() as u32;
            DnsEntry { ip: None, dns_time_ms: dns_time, error: Some(PingErrorKind::DnsTimeout) }
        }
    }
}

// ─── TCP-пинг по IP (без DNS) ─────────────────────────────────────────────────

/// TCP-пинг по уже известному IP-адресу (без DNS-фазы)
pub async fn ping_tcp_ip(
    ip: std::net::IpAddr,
    port: u16,
    timeout_ms: u64,
) -> (bool, Option<u32>, Option<PingErrorKind>) {
    let timeout_duration = Duration::from_millis(timeout_ms);
    let start = Instant::now();

    match timeout(timeout_duration, TcpStream::connect((ip, port))).await {
        Ok(Ok(_stream)) => {
            (true, Some(start.elapsed().as_millis() as u32), None)
        }
        Ok(Err(e)) => {
            let tcp_time = start.elapsed().as_millis() as u32;
            let error_kind = match e.kind() {
                std::io::ErrorKind::ConnectionRefused => PingErrorKind::TcpRefused,
                std::io::ErrorKind::ConnectionReset => PingErrorKind::TcpReset,
                std::io::ErrorKind::TimedOut => PingErrorKind::TcpTimeout,
                _ => PingErrorKind::Unknown,
            };
            (false, Some(tcp_time), Some(error_kind))
        }
        Err(_) => {
            let tcp_time = start.elapsed().as_millis() as u32;
            (false, Some(tcp_time), Some(PingErrorKind::TcpTimeout))
        }
    }
}

// ─── Полный TCP-пинг (DNS + TCP, для FFI утилиты) ─────────────────────────────

/// Проверяет доступность домена через TCP ping на заданный порт, используя hickory-resolver.
pub async fn ping_tcp(resolver: &TokioAsyncResolver, domain: String, port: u16, timeout_ms: u64) -> PingResult {
    let timeout_duration = Duration::from_millis(timeout_ms);
    let start_total = Instant::now();

    // 1. Измеряем время DNS резолвинга
    let start_dns = Instant::now();
    let lookup_result = match timeout(timeout_duration, resolver.lookup_ip(&domain)).await {
        Ok(Ok(response)) => response,
        Ok(Err(_e)) => {
            return PingResult {
                success: false,
                total_time_ms: Some(start_total.elapsed().as_millis() as u32),
                dns_time_ms: Some(start_dns.elapsed().as_millis() as u32),
                tcp_time_ms: None,
                error: Some(PingErrorKind::DnsFailed),
            };
        }
        Err(_) => {
            return PingResult {
                success: false,
                total_time_ms: Some(start_total.elapsed().as_millis() as u32),
                dns_time_ms: Some(start_dns.elapsed().as_millis() as u32),
                tcp_time_ms: None,
                error: Some(PingErrorKind::DnsTimeout),
            };
        }
    };
    
    let dns_time = start_dns.elapsed().as_millis() as u32;

    // Берем первый доступный IPv4 адрес, остальные отсеиваем
    let ip = match lookup_result.iter().find(|ip| ip.is_ipv4()) {
        Some(ip) => ip,
        None => {
            return PingResult {
                success: false,
                total_time_ms: Some(start_total.elapsed().as_millis() as u32),
                dns_time_ms: Some(dns_time),
                tcp_time_ms: None,
                error: Some(PingErrorKind::DnsNoRecord),
            };
        }
    };

    // 2. Измеряем время TCP соединения
    let start_tcp = Instant::now();
    let remaining_timeout = timeout_duration.saturating_sub(start_total.elapsed());
    
    if remaining_timeout.is_zero() {
        return PingResult {
            success: false,
            total_time_ms: Some(start_total.elapsed().as_millis() as u32),
            dns_time_ms: Some(dns_time),
            tcp_time_ms: None,
            error: Some(PingErrorKind::TcpTimeout),
        };
    }

    match timeout(remaining_timeout, TcpStream::connect((ip, port))).await {
        Ok(Ok(_stream)) => {
            let tcp_time = start_tcp.elapsed().as_millis() as u32;
            PingResult {
                success: true,
                total_time_ms: Some(start_total.elapsed().as_millis() as u32),
                dns_time_ms: Some(dns_time),
                tcp_time_ms: Some(tcp_time),
                error: None,
            }
        }
        Ok(Err(e)) => {
            let tcp_time = start_tcp.elapsed().as_millis() as u32;
            let error_kind = match e.kind() {
                std::io::ErrorKind::ConnectionRefused => PingErrorKind::TcpRefused,
                std::io::ErrorKind::ConnectionReset => PingErrorKind::TcpReset,
                std::io::ErrorKind::TimedOut => PingErrorKind::TcpTimeout,
                _ => PingErrorKind::Unknown,
            };
            PingResult {
                success: false,
                total_time_ms: Some(start_total.elapsed().as_millis() as u32),
                dns_time_ms: Some(dns_time),
                tcp_time_ms: Some(tcp_time),
                error: Some(error_kind),
            }
        }
        Err(_) => {
            let tcp_time = start_tcp.elapsed().as_millis() as u32;
            PingResult {
                success: false,
                total_time_ms: Some(start_total.elapsed().as_millis() as u32),
                dns_time_ms: Some(dns_time),
                tcp_time_ms: Some(tcp_time),
                error: Some(PingErrorKind::TcpTimeout),
            }
        }
    }
}
