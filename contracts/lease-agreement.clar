;; lease-agreement.clar
;; This contract manages lease terms between landlords and tenants

(define-data-var contract-owner principal tx-sender)

;; Lease status enum
(define-constant STATUS-PENDING u0)
(define-constant STATUS-ACTIVE u1)
(define-constant STATUS-TERMINATED u2)
(define-constant STATUS-EXPIRED u3)

;; Lease data structure
(define-map leases
  { lease-id: uint }
  {
    property-id: uint,
    landlord: principal,
    tenant: principal,
    start-block: uint,
    end-block: uint,
    monthly-rent: uint,
    security-deposit: uint,
    status: uint,
    last-payment-block: uint
  }
)

;; Payment history
(define-map payment-history
  { lease-id: uint, payment-id: uint }
  {
    amount: uint,
    block: uint,
    confirmed: bool
  }
)

;; Payment counter per lease
(define-map payment-counters
  { lease-id: uint }
  { counter: uint }
)

;; Initialize contract
(define-public (initialize)
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u300))
    (ok true)
  )
)

;; Create a new lease
(define-public (create-lease
  (lease-id uint)
  (property-id uint)
  (tenant principal)
  (start-block uint)
  (end-block uint)
  (monthly-rent uint)
  (security-deposit uint)
)
  (begin
    (asserts! (> end-block start-block) (err u301))
    (asserts! (>= start-block block-height) (err u302))

    (map-set leases
      { lease-id: lease-id }
      {
        property-id: property-id,
        landlord: tx-sender,
        tenant: tenant,
        start-block: start-block,
        end-block: end-block,
        monthly-rent: monthly-rent,
        security-deposit: security-deposit,
        status: STATUS-PENDING,
        last-payment-block: u0
      }
    )

    (map-set payment-counters
      { lease-id: lease-id }
      { counter: u0 }
    )

    (ok true)
  )
)

;; Accept a lease (tenant)
(define-public (accept-lease (lease-id uint))
  (let (
    (lease (unwrap! (map-get? leases { lease-id: lease-id }) (err u303)))
  )
    (asserts! (is-eq tx-sender (get tenant lease)) (err u304))
    (asserts! (is-eq (get status lease) STATUS-PENDING) (err u305))

    (map-set leases
      { lease-id: lease-id }
      (merge lease {
        status: STATUS-ACTIVE
      })
    )

    (ok true)
  )
)

;; Record a rent payment
(define-public (record-payment (lease-id uint) (amount uint))
  (let (
    (lease (unwrap! (map-get? leases { lease-id: lease-id }) (err u306)))
    (counter-data (default-to { counter: u0 } (map-get? payment-counters { lease-id: lease-id })))
    (payment-id (get counter counter-data))
  )
    (asserts! (is-eq (get status lease) STATUS-ACTIVE) (err u307))
    (asserts! (is-eq tx-sender (get tenant lease)) (err u308))

    (map-set payment-history
      { lease-id: lease-id, payment-id: payment-id }
      {
        amount: amount,
        block: block-height,
        confirmed: false
      }
    )

    (map-set payment-counters
      { lease-id: lease-id }
      { counter: (+ payment-id u1) }
    )

    (ok payment-id)
  )
)

;; Confirm a payment (landlord)
(define-public (confirm-payment (lease-id uint) (payment-id uint))
  (let (
    (lease (unwrap! (map-get? leases { lease-id: lease-id }) (err u309)))
    (payment (unwrap! (map-get? payment-history { lease-id: lease-id, payment-id: payment-id }) (err u310)))
  )
    (asserts! (is-eq tx-sender (get landlord lease)) (err u311))
    (asserts! (not (get confirmed payment)) (err u312))

    (map-set payment-history
      { lease-id: lease-id, payment-id: payment-id }
      (merge payment { confirmed: true })
    )

    (map-set leases
      { lease-id: lease-id }
      (merge lease { last-payment-block: block-height })
    )

    (ok true)
  )
)

;; Terminate a lease (can be called by either party)
(define-public (terminate-lease (lease-id uint))
  (let (
    (lease (unwrap! (map-get? leases { lease-id: lease-id }) (err u313)))
  )
    (asserts! (or (is-eq tx-sender (get landlord lease)) (is-eq tx-sender (get tenant lease))) (err u314))
    (asserts! (is-eq (get status lease) STATUS-ACTIVE) (err u315))

    (map-set leases
      { lease-id: lease-id }
      (merge lease { status: STATUS-TERMINATED })
    )

    (ok true)
  )
)

;; Get lease details
(define-read-only (get-lease (lease-id uint))
  (map-get? leases { lease-id: lease-id })
)

;; Get payment details
(define-read-only (get-payment (lease-id uint) (payment-id uint))
  (map-get? payment-history { lease-id: lease-id, payment-id: payment-id })
)

;; Check if lease is active
(define-read-only (is-lease-active (lease-id uint))
  (let (
    (lease (default-to { status: u0 } (map-get? leases { lease-id: lease-id })))
  )
    (is-eq (get status lease) STATUS-ACTIVE)
  )
)

;; Update lease status if expired
(define-public (check-lease-expiry (lease-id uint))
  (let (
    (lease (unwrap! (map-get? leases { lease-id: lease-id }) (err u316)))
  )
    (if (and
          (is-eq (get status lease) STATUS-ACTIVE)
          (>= block-height (get end-block lease))
        )
      (begin
        (map-set leases
          { lease-id: lease-id }
          (merge lease { status: STATUS-EXPIRED })
        )
        (ok true)
      )
      (ok false)
    )
  )
)
