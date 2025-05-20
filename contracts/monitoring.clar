;; Monitoring Contract
;; Tracks conditions affecting supply chain

(define-data-var admin principal tx-sender)

(define-map monitoring-parameters
  { param-id: (string-ascii 64) }
  {
    name: (string-ascii 100),
    description: (string-ascii 256),
    threshold-min: int,
    threshold-max: int,
    unit: (string-ascii 20),
    created-at: uint,
    last-updated: uint
  }
)

(define-map monitoring-data
  { param-id: (string-ascii 64), timestamp: uint }
  {
    value: int,
    reported-by: principal,
    notes: (string-ascii 256)
  }
)

(define-read-only (get-parameter (param-id (string-ascii 64)))
  (map-get? monitoring-parameters { param-id: param-id })
)

(define-read-only (get-monitoring-data (param-id (string-ascii 64)) (timestamp uint))
  (map-get? monitoring-data { param-id: param-id, timestamp: timestamp })
)

(define-read-only (is-threshold-breached (param-id (string-ascii 64)) (value int))
  (let ((param (unwrap! (map-get? monitoring-parameters { param-id: param-id }) false)))
    (or (< value (get threshold-min param)) (> value (get threshold-max param)))
  )
)

(define-public (add-parameter
    (param-id (string-ascii 64))
    (name (string-ascii 100))
    (description (string-ascii 256))
    (threshold-min int)
    (threshold-max int)
    (unit (string-ascii 20)))
  (let ((current-time (unwrap-panic (get-block-info? time (- block-height u1)))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u3)) ;; not admin
    (asserts! (<= threshold-min threshold-max) (err u4)) ;; invalid thresholds

    (if (is-none (map-get? monitoring-parameters { param-id: param-id }))
      (begin
        (map-set monitoring-parameters
          { param-id: param-id }
          {
            name: name,
            description: description,
            threshold-min: threshold-min,
            threshold-max: threshold-max,
            unit: unit,
            created-at: current-time,
            last-updated: current-time
          }
        )
        (ok true))
      (err u1)) ;; parameter already exists
  )
)

(define-public (update-parameter
    (param-id (string-ascii 64))
    (name (string-ascii 100))
    (description (string-ascii 256))
    (threshold-min int)
    (threshold-max int)
    (unit (string-ascii 20)))
  (let ((current-time (unwrap-panic (get-block-info? time (- block-height u1))))
        (param (unwrap! (map-get? monitoring-parameters { param-id: param-id }) (err u2)))) ;; parameter not found
    (asserts! (is-eq tx-sender (var-get admin)) (err u3)) ;; not admin
    (asserts! (<= threshold-min threshold-max) (err u4)) ;; invalid thresholds

    (map-set monitoring-parameters
      { param-id: param-id }
      (merge param {
        name: name,
        description: description,
        threshold-min: threshold-min,
        threshold-max: threshold-max,
        unit: unit,
        last-updated: current-time
      })
    )
    (ok true)
  )
)

(define-public (record-data
    (param-id (string-ascii 64))
    (value int)
    (notes (string-ascii 256)))
  (let ((current-time (unwrap-panic (get-block-info? time (- block-height u1)))))
    (asserts! (is-some (map-get? monitoring-parameters { param-id: param-id })) (err u2)) ;; parameter not found

    (map-set monitoring-data
      { param-id: param-id, timestamp: current-time }
      {
        value: value,
        reported-by: tx-sender,
        notes: notes
      }
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
