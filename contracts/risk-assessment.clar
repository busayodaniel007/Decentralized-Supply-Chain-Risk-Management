;; Risk Assessment Contract
;; Identifies potential disruption factors

(define-data-var admin principal tx-sender)

;; Risk severity: 0 = low, 1 = medium, 2 = high, 3 = critical
(define-map risk-factors
  { risk-id: (string-ascii 64) }
  {
    description: (string-ascii 256),
    category: (string-ascii 64),
    severity: uint,
    probability: uint,
    impact: uint,
    created-by: principal,
    created-at: uint,
    last-updated: uint
  }
)

(define-map entity-risks
  { entity-id: (string-ascii 64), risk-id: (string-ascii 64) }
  { assigned: bool }
)

(define-read-only (get-risk-factor (risk-id (string-ascii 64)))
  (map-get? risk-factors { risk-id: risk-id })
)

(define-read-only (is-entity-at-risk (entity-id (string-ascii 64)) (risk-id (string-ascii 64)))
  (default-to { assigned: false } (map-get? entity-risks { entity-id: entity-id, risk-id: risk-id }))
)

(define-public (add-risk-factor
    (risk-id (string-ascii 64))
    (description (string-ascii 256))
    (category (string-ascii 64))
    (severity uint)
    (probability uint)
    (impact uint))
  (let ((current-time (unwrap-panic (get-block-info? time (- block-height u1)))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u3)) ;; not admin
    (asserts! (<= severity u3) (err u4)) ;; invalid severity
    (asserts! (<= probability u10) (err u5)) ;; invalid probability (0-10)
    (asserts! (<= impact u10) (err u6)) ;; invalid impact (0-10)

    (if (is-none (map-get? risk-factors { risk-id: risk-id }))
      (begin
        (map-set risk-factors
          { risk-id: risk-id }
          {
            description: description,
            category: category,
            severity: severity,
            probability: probability,
            impact: impact,
            created-by: tx-sender,
            created-at: current-time,
            last-updated: current-time
          }
        )
        (ok true))
      (err u1)) ;; risk already exists
  )
)

(define-public (update-risk-factor
    (risk-id (string-ascii 64))
    (description (string-ascii 256))
    (category (string-ascii 64))
    (severity uint)
    (probability uint)
    (impact uint))
  (let ((current-time (unwrap-panic (get-block-info? time (- block-height u1))))
        (risk (unwrap! (map-get? risk-factors { risk-id: risk-id }) (err u2)))) ;; risk not found
    (asserts! (is-eq tx-sender (var-get admin)) (err u3)) ;; not admin
    (asserts! (<= severity u3) (err u4)) ;; invalid severity
    (asserts! (<= probability u10) (err u5)) ;; invalid probability (0-10)
    (asserts! (<= impact u10) (err u6)) ;; invalid impact (0-10)

    (map-set risk-factors
      { risk-id: risk-id }
      (merge risk {
        description: description,
        category: category,
        severity: severity,
        probability: probability,
        impact: impact,
        last-updated: current-time
      })
    )
    (ok true)
  )
)

(define-public (assign-risk-to-entity (entity-id (string-ascii 64)) (risk-id (string-ascii 64)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u3)) ;; not admin
    (asserts! (is-some (map-get? risk-factors { risk-id: risk-id })) (err u2)) ;; risk not found

    (map-set entity-risks
      { entity-id: entity-id, risk-id: risk-id }
      { assigned: true }
    )
    (ok true)
  )
)

(define-public (remove-risk-from-entity (entity-id (string-ascii 64)) (risk-id (string-ascii 64)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u3)) ;; not admin
    (map-delete entity-risks { entity-id: entity-id, risk-id: risk-id })
    (ok true)
  )
)

(define-public (update-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u3)) ;; not admin
    (var-set admin new-admin)
    (ok true)
  )
)
