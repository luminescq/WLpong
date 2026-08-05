#[cfg(test)]
mod tests {
    use crate::checker::{CheckConfig, DomainGroup, GroupType, VerdictMode};

    #[tokio::test]
    async fn test_check_domains_cs_verdict() {
        // Тестируем CS вердикт (открытый интернет, доступны все)
        let config = CheckConfig {
            groups: vec![
                DomainGroup {
                    id: GroupType::WL,
                    name: "Whitelist".to_string(),
                    domains: vec!["google.com".to_string()],
                },
                DomainGroup {
                    id: GroupType::BL,
                    name: "Blacklist".to_string(),
                    domains: vec!["example.com".to_string()],
                },
            ],
            timeout_ms: 3000,
            port: 443,
            verdict_mode: Some(VerdictMode::DefaultRules),
            custom_dns: None,
        };

        let result = crate::checker::check_domains(config).await;
        
        println!("Verdict: {:?}", result.verdict);
        if let Some(stats) = result.stats {
            println!("Stats: WL={}, BL={}, NT={}", 
                stats.wl_accessible,
                stats.bl_accessible,
                stats.nt_accessible
            );
        }
        
        for detail in &result.details {
            println!("  {} ({:?}): {} ({}ms)", 
                detail.domain,
                detail.group,
                if detail.accessible { "✓" } else { "✗" },
                detail.total_time_ms.unwrap_or(0)
            );
        }
    }

    #[tokio::test]
    async fn test_ping_single_domain() {
        let resolver = crate::ping::get_resolver(None);

        let result = crate::ping::ping_tcp(&resolver, "google.com".to_string(), 443, 3000).await;
        
        println!("Ping google.com:443");
        println!("  Success: {}", result.success);
        println!("  Total Time: {:?}ms", result.total_time_ms);
        println!("  DNS Time: {:?}ms", result.dns_time_ms);
        println!("  TCP Time: {:?}ms", result.tcp_time_ms);
        println!("  Error: {:?}", result.error);
        
        assert!(result.success, "Google should be accessible");
    }
}
