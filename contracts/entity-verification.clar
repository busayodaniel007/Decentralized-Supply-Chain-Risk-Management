;; Alert Management Contract
;; Handles notification of potential issues

(define-data-var admin principal tx-sender)

;; Alert status: 0 = active, 1 = acknowledged, 2 = resolved
;; Alert severity: 0 = low, 1 = medium, 2 = high, 3 = critical
(define-map alerts
  { alert-id: (string-ascii 64) }
  {
    title: (string-ascii 100),
    description: (string-ascii 256),
    severity: uint,
    status: uint,
    entity-id: (string-ascii 64),
    param-id: (optional (string-ascii 64)),
    risk-id: (optional (string-ascii 64)),
    created-by: principal,
    created-at: uint,
    acknowledged-at: (optional uint),
    resolved-at: (optional uint),
    last-updated: uint
  }
)

(define-read-only (get-alert (alert-id (string-ascii 64)))
  (map-get? alerts { alert-id: alert-id })
)

(define-public (create-alert
    (alert-id (string-ascii 64))
    (title (string-ascii 100))
    (description (string-ascii 256))
    (severity uint)
    (entity-id (string-ascii 64))
    (param-id (optional (string-ascii 64)))
    (risk-id (optional (string-ascii 64))))
  (let ((current-time (unwrap-panic (get-block-info? time (- block-height u1)))))
    (asserts! (<= severity u3) (err u4)) ;; invalid severity

    (if (is-none (map-get? alerts { alert-id: alert-id }))
      (begin
        (map-set alerts
          { alert-id: alert-id }
          {
            title: title,
            description: description,
            severity: severity,
            status: u0, ;; active
            entity-id: entity-id,
            param-id: param-id,
            risk-id: risk-id,
            created-by: tx-sender,
            created-at: current-time,
            acknowledged-at: none,
            resolved-at: none,
            last-updated: current-time
          }
        )
        (ok true))
      (err u1)) ;; alert already exists
  )
)

(define-public (acknowledge-alert (alert-id (string-ascii 64)))
  (let ((current-time (unwrap-panic (get-block-info? time (- block-height u1))))
        (alert (unwrap! (map-get? alerts { alert-id: alert-id }) (err u2)))) ;; alert not found

    (asserts! (is-eq (get status alert) u0) (err u5)) ;; alert not active

    (map-set alerts
      { alert-id: alert-id }
      (merge alert {
        status: u1, ;; acknowledged
        acknowledged-at: (some current-time),
        last-updated: current-time
      })
    )
    (ok true)
  )
)

(define-public (resolve-alert (alert-id (string-ascii 64)))
  (let ((current-time (unwrap-panic (get-block-info? time (- block-height u1))))
        (alert (unwrap! (map-get? alerts { alert-id: alert-id }) (err u2)))) ;; alert not found

    (asserts! (not (is-eq (get status alert) u2)) (err u6)) ;; alert already resolved

    (map-set alerts
      { alert-id: alert-id }
      (merge alert {
        status: u2, ;; resolved
        resolved-at: (some current-time),
        last-updated: current-time
      })
    )
    (ok true)
  )
)

(define-public (update-alert-severity (alert-id (string-ascii 64)) (severity uint))
  (let ((current-time (unwrap-panic (get-block-info? time (- block-height u1))))
        (alert (unwrap! (map-get? alerts { alert-id: alert-id }) (err u2)))) ;; alert not found

    (asserts! (is-eq tx-sender (var-get admin)) (err u3)) ;; not admin
    (asserts! (<= severity u3) (err u4)) ;; invalid severity
    (asserts! (not (is-eq (get status alert) u2)) (err u6)) ;; alert already resolved

    (map-set alerts
      { alert-id: alert-id }
      (merge alert {
        severity: severity,
        last-updated: current-time
      })
    )
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
