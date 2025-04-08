;; tenant-verification.clar
;; This contract confirms financial qualifications of lessees

(define-data-var contract-owner principal tx-sender)

;; Tenant data structure
(define-map tenants
  { tenant-id: uint }
  {
    principal: principal,
    name: (string-utf8 100),
    credit-score: uint,
    verified: bool,
    annual-income: uint,
    verification-expiry: uint
  }
)

;; Authorized verifiers
(define-map authorized-verifiers
  { verifier: principal }
  { authorized: bool }
)

;; Initialize contract
(define-public (initialize)
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u200))
    (ok true)
  )
)

;; Register as a tenant
(define-public (register-tenant (tenant-id uint) (name (string-utf8 100)))
  (begin
    (asserts! (not (default-to false (get verified (map-get? tenants { tenant-id: tenant-id })))) (err u201))
    (map-set tenants
      { tenant-id: tenant-id }
      {
        principal: tx-sender,
        name: name,
        credit-score: u0,
        verified: false,
        annual-income: u0,
        verification-expiry: u0
      }
    )
    (ok true)
  )
)

;; Authorize a verifier
(define-public (add-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u202))
    (map-set authorized-verifiers
      { verifier: verifier }
      { authorized: true }
    )
    (ok true)
  )
)

;; Remove a verifier
(define-public (remove-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u203))
    (map-delete authorized-verifiers { verifier: verifier })
    (ok true)
  )
)

;; Verify a tenant
(define-public (verify-tenant (tenant-id uint) (credit-score uint) (annual-income uint) (validity-period uint))
  (let (
    (tenant (unwrap! (map-get? tenants { tenant-id: tenant-id }) (err u204)))
    (verifier-status (default-to { authorized: false } (map-get? authorized-verifiers { verifier: tx-sender })))
  )
    (asserts! (get authorized verifier-status) (err u205))
    (asserts! (<= credit-score u850) (err u206))

    (map-set tenants
      { tenant-id: tenant-id }
      (merge tenant {
        credit-score: credit-score,
        verified: true,
        annual-income: annual-income,
        verification-expiry: (+ block-height validity-period)
      })
    )
    (ok true)
  )
)

;; Get tenant details
(define-read-only (get-tenant (tenant-id uint))
  (map-get? tenants { tenant-id: tenant-id })
)

;; Check if tenant verification is valid
(define-read-only (is-tenant-verified (tenant-id uint))
  (let (
    (tenant (default-to { verified: false, verification-expiry: u0 } (map-get? tenants { tenant-id: tenant-id })))
  )
    (and (get verified tenant) (< block-height (get verification-expiry tenant)))
  )
)

;; Check if verifier is authorized
(define-read-only (is-authorized-verifier (verifier principal))
  (default-to false (get authorized (map-get? authorized-verifiers { verifier: verifier })))
)
