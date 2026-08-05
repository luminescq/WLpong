use flutter_rust_bridge::frb;

// Реэкспортируем все публичные типы из внутренних модулей
pub use crate::checker::{
    CheckConfig, CheckResult, DomainGroup, DomainResult,
    GroupType, Stats, Verdict, VerdictMode,
};
pub use crate::ping::{PingResult, PingErrorKind};

// ─── FFI точки входа ──────────────────────────────────────────────────────────

/// Универсальная проверка доменов.
///
/// Дефолтный профиль: передаём группы WL/BL/NT + `verdict_mode: Some(DefaultRules)`
/// → возвращает `CheckResult` с `verdict` и `stats`.
///
/// Кастомный профиль: передаём группу Custom + `verdict_mode: None`
/// → возвращает `CheckResult` только с `details` (пинг без классификации).
#[frb]
pub async fn check_network_restrictions(config: CheckConfig) -> CheckResult {
    crate::checker::check_domains(config).await
}

/// Пинг одного домена — утилита для отладки
#[frb]
pub async fn ping_domain(domain: String, port: u16, timeout_ms: u64) -> PingResult {
    let resolver = crate::ping::get_resolver(None);
    crate::ping::ping_tcp(&resolver, domain, port, timeout_ms).await
}
