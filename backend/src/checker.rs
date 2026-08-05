use std::collections::{HashMap, HashSet};

// ─── Типы групп ───────────────────────────────────────────────────────────────

/// Тип группы доменов
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum GroupType {
    WL,     // Whitelist — должны быть недоступны при БС
    BL,     // Blacklist — должны быть доступны при БС
    NT,     // Neutral   — вспомогательные
    Custom, // Пользовательские домены — не влияют на вердикт
}

// ─── Режим вердикта ───────────────────────────────────────────────────────────

/// Шаблон классификации. Передаётся только для дефолтного профиля.
/// None = просто пинг, вердикт не вычисляется.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum VerdictMode {
    /// Стандартная классификация по WL / BL / NT
    DefaultRules,
}

// ─── Входные данные ───────────────────────────────────────────────────────────

/// Группа доменов с типом
#[derive(Debug, Clone)]
pub struct DomainGroup {
    pub id: GroupType,
    pub name: String,
    pub domains: Vec<String>,
}

/// Универсальная конфигурация проверки
#[derive(Debug, Clone)]
pub struct CheckConfig {
    pub groups: Vec<DomainGroup>,
    pub timeout_ms: u64,
    pub port: u16,
    /// None → просто пинг (кастомный профиль)
    /// Some(_) → пинг + классификация (дефолтный профиль)
    pub verdict_mode: Option<VerdictMode>,
    pub custom_dns: Option<String>,
}

// ─── Выходные данные ──────────────────────────────────────────────────────────

/// Статистика по группам (только при VerdictMode::DefaultRules)
#[derive(Debug, Clone, Default)]
pub struct Stats {
    pub wl_accessible: u32,
    pub bl_accessible: u32,
    pub nt_accessible: u32,
}

/// Результат проверки одного домена
#[derive(Debug, Clone)]
pub struct DomainResult {
    pub domain: String,
    pub group: GroupType,
    pub accessible: bool,
    pub total_time_ms: Option<u32>,
    pub dns_time_ms: Option<u32>,
    pub tcp_time_ms: Option<u32>,
    pub error: Option<crate::ping::PingErrorKind>,
}

/// Вердикт (только при VerdictMode::DefaultRules)
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Verdict {
    BS, // Белый Список — жёсткие ограничения
    CS, // Чёрный Список — открытый интернет
}

/// Результат всей проверки
#[derive(Debug, Clone)]
pub struct CheckResult {
    /// None если verdict_mode == None
    pub verdict: Option<Verdict>,
    /// None если verdict_mode == None
    pub stats: Option<Stats>,
    /// Результаты по каждому домену — всегда заполнен
    pub details: Vec<DomainResult>,
}

// ─── Логика ───────────────────────────────────────────────────────────────────

/// Универсальная проверка доменов.
///
/// - Если `config.verdict_mode == None` → пингует домены параллельно,
///   возвращает только `details`. `verdict` и `stats` — `None`.
/// - Если `config.verdict_mode == Some(DefaultRules)` → пингует + классифицирует.
///
/// Оптимизации:
/// - Дедупликация DNS: каждый уникальный домен резолвится ровно один раз.
/// - Двухфазная проверка: сначала батчевый DNS, затем батчевый TCP.
/// - Семафор 25 для параллельных TCP-соединений.
pub async fn check_domains(config: CheckConfig) -> CheckResult {
    // Получаем резолвер (кэшируется для кастомного DNS)
    let resolver = crate::ping::get_resolver(config.custom_dns.clone());

    // ── Фаза 1: Дедупликация и батчевый DNS ──────────────────────────────────

    let mut unique_domains: Vec<String> = Vec::new();
    let mut seen: HashSet<String> = HashSet::new();

    for group in &config.groups {
        for domain in &group.domains {
            if seen.insert(domain.clone()) {
                unique_domains.push(domain.clone());
            }
        }
    }

    // Параллельный DNS-резолв всех уникальных доменов (без семафора — DNS легкий)
    let mut dns_tasks = Vec::with_capacity(unique_domains.len());
    for domain in &unique_domains {
        let domain = domain.clone();
        let resolver = resolver.clone();
        let timeout_ms = config.timeout_ms;
        dns_tasks.push(tokio::spawn(async move {
            let entry = crate::ping::resolve_dns(&resolver, &domain, timeout_ms).await;
            (domain, entry)
        }));
    }

    let mut dns_cache: HashMap<String, crate::ping::DnsEntry> =
        HashMap::with_capacity(unique_domains.len());

    for task in dns_tasks {
        if let Ok((domain, entry)) = task.await {
            dns_cache.insert(domain, entry);
        }
    }

    let dns_cache = std::sync::Arc::new(dns_cache);

    // ── Фаза 2: Батчевый TCP-пинг с кэшированными IP ────────────────────────

    let semaphore = std::sync::Arc::new(tokio::sync::Semaphore::new(25));
    let mut tasks = Vec::new();

    for group in &config.groups {
        for domain in &group.domains {
            let domain = domain.clone();
            let group_id = group.id;
            let port = config.port;
            let timeout_ms = config.timeout_ms;
            let sem = semaphore.clone();
            let dns_cache = dns_cache.clone();

            tasks.push(tokio::spawn(async move {
                let _permit = sem.acquire().await.unwrap();

                // Достаём результат DNS из кэша
                let dns_entry = dns_cache.get(&domain).cloned().unwrap_or(
                    crate::ping::DnsEntry {
                        ip: None,
                        dns_time_ms: 0,
                        error: Some(crate::ping::PingErrorKind::Unknown),
                    }
                );

                match dns_entry.ip {
                    Some(ip) => {
                        // DNS успешен — делаем TCP-пинг
                        let (success, tcp_time, tcp_error) =
                            crate::ping::ping_tcp_ip(ip, port, timeout_ms).await;

                        DomainResult {
                            domain,
                            group: group_id,
                            accessible: success,
                            total_time_ms: Some(dns_entry.dns_time_ms + tcp_time.unwrap_or(0)),
                            dns_time_ms: Some(dns_entry.dns_time_ms),
                            tcp_time_ms: tcp_time,
                            error: tcp_error,
                        }
                    }
                    None => {
                        // DNS не удался — сразу фейл
                        DomainResult {
                            domain,
                            group: group_id,
                            accessible: false,
                            total_time_ms: Some(dns_entry.dns_time_ms),
                            dns_time_ms: Some(dns_entry.dns_time_ms),
                            tcp_time_ms: None,
                            error: dns_entry.error,
                        }
                    }
                }
            }));
        }
    }

    // Собираем результаты
    let mut details = Vec::with_capacity(tasks.len());
    for task in tasks {
        if let Ok(result) = task.await {
            details.push(result);
        }
    }

    // ── Вердикт ──────────────────────────────────────────────────────────────

    let (verdict, stats) = match config.verdict_mode {
        Some(VerdictMode::DefaultRules) => {
            let mut s = Stats::default();

            for d in &details {
                if d.accessible {
                    match d.group {
                        GroupType::WL => s.wl_accessible += 1,
                        GroupType::BL => s.bl_accessible += 1,
                        GroupType::NT => s.nt_accessible += 1,
                        GroupType::Custom => {} // намеренно игнорируем
                    }
                }
            }

            let v = classify(&s);
            (Some(v), Some(s))
        }
        None => (None, None),
    };

    CheckResult { verdict, stats, details }
}

/// Алгоритм классификации (только WL / BL / NT)
fn classify(stats: &Stats) -> Verdict {
    if stats.bl_accessible > 0 {
        return Verdict::CS;
    }
    if stats.nt_accessible > 0 {
        return Verdict::CS;
    }
    Verdict::BS
}
