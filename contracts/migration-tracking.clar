;; Mitigation Tracking Contract
;; Records actions to address risks

(define-data-var admin principal tx-sender)

;; Mitigation status: 0 = planned, 1 = in-progress, 2 = completed, 3 = failed
(define-map mitigation-plans
  { plan-id: (string-ascii 64) }
  {
    title: (string-ascii 100),
    description: (string-ascii 256),
    status: uint,
    alert-id: (optional (string-ascii 64)),
    risk-id: (optional (string-ascii 64)),
    entity-id: (string-ascii 64),
    assigned-to: principal,
    created-by: principal,
    created-at: uint,
    deadline: uint,
    completed-at: (optional uint),
    last-updated: uint
  }
)

(define-map mitigation-actions
  { plan-id: (string-ascii 64), action-id: (string-ascii 64) }
  {
    description: (string-ascii 256),
    status: uint,
    created-by: principal,
    created-at: uint,
    completed-at: (optional uint),
    notes: (string-ascii 256)
  }
)

(define-read-only (get-mitigation-plan (plan-id (string-ascii 64)))
  (map-get? mitigation-plans { plan-id: plan-id })
)

(define-read-only (get-mitigation-action (plan-id (string-ascii 64)) (action-id (string-ascii 64)))
  (map-get? mitigation-actions { plan-id: plan-id, action-id: action-id })
)

(define-public (create-mitigation-plan
    (plan-id (string-ascii 64))
    (title (string-ascii 100))
    (description (string-ascii 256))
    (alert-id (optional (string-ascii 64)))
    (risk-id (optional (string-ascii 64)))
    (entity-id (string-ascii 64))
    (assigned-to principal)
    (deadline uint))
  (let ((current-time (unwrap-panic (get-block-info? time (- block-height u1)))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u3)) ;; not admin
    (asserts! (> deadline current-time) (err u4)) ;; deadline must be in the future

    (if (is-none (map-get? mitigation-plans { plan-id: plan-id }))
      (begin
        (map-set mitigation-plans
          { plan-id: plan-id }
          {
            title: title,
            description: description,
            status: u0, ;; planned
            alert-id: alert-id,
            risk-id: risk-id,
            entity-id: entity-id,
            assigned-to: assigned-to,
            created-by: tx-sender,
            created-at: current-time,
            deadline: deadline,
            completed-at: none,
            last-updated: current-time
          }
        )
        (ok true))
      (err u1)) ;; plan already exists
  )
)

(define-public (update-mitigation-status (plan-id (string-ascii 64)) (status uint))
  (let ((current-time (unwrap-panic (get-block-info? time (- block-height u1))))
        (plan (unwrap! (map-get? mitigation-plans { plan-id: plan-id }) (err u2)))) ;; plan not found

    (asserts! (or (is-eq tx-sender (var-get admin)) (is-eq tx-sender (get assigned-to plan))) (err u3)) ;; not authorized
    (asserts! (<= status u3) (err u5)) ;; invalid status

    (map-set mitigation-plans
      { plan-id: plan-id }
      (merge plan {
        status: status,
        completed-at: (if (is-eq status u2) (some current-time) (get completed-at plan)),
        last-updated: current-time
      })
    )
    (ok true)
  )
)

(define-public (add-mitigation-action
    (plan-id (string-ascii 64))
    (action-id (string-ascii 64))
    (description (string-ascii 256))
    (notes (string-ascii 256)))
  (let ((current-time (unwrap-panic (get-block-info? time (- block-height u1))))
        (plan (unwrap! (map-get? mitigation-plans { plan-id: plan-id }) (err u2)))) ;; plan not found

    (asserts! (or (is-eq tx-sender (var-get admin)) (is-eq tx-sender (get assigned-to plan))) (err u3)) ;; not authorized

    (if (is-none (map-get? mitigation-actions { plan-id: plan-id, action-id: action-id }))
      (begin
        (map-set mitigation-actions
          { plan-id: plan-id, action-id: action-id }
          {
            description: description,
            status: u0, ;; planned
            created-by: tx-sender,
            created-at: current-time,
            completed-at: none,
            notes: notes
          }
        )
        (ok true))
      (err u6)) ;; action already exists
  )
)

(define-public (complete-mitigation-action (plan-id (string-ascii 64)) (action-id (string-ascii 64)))
  (let ((current-time (unwrap-panic (get-block-info? time (- block-height u1))))
        (plan (unwrap! (map-get? mitigation-plans { plan-id: plan-id }) (err u2))) ;; plan not found
        (action (unwrap! (map-get? mitigation-actions { plan-id: plan-id, action-id: action-id }) (err u7)))) ;; action not found

    (asserts! (or (is-eq tx-sender (var-get admin)) (is-eq tx-sender (get assigned-to plan))) (err u3)) ;; not authorized

    (map-set mitigation-actions
      { plan-id: plan-id, action-id: action-id }
      (merge action {
        status: u2, ;; completed
        completed-at: (some current-time)
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
