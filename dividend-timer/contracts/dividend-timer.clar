;; Dividend Timer - Scheduled Dividend Payouts
;; A time-locked contract for releasing dividend funds after specified delays

;; Contract owner
(define-constant contract-owner tx-sender)

;; Error codes
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-not-ready (err u102))
(define-constant err-already-claimed (err u103))
(define-constant err-insufficient-funds (err u104))
(define-constant err-invalid-amount (err u105))
(define-constant err-invalid-delay (err u106))

;; Data structures
(define-map dividend-schedules
  { schedule-id: uint }
  {
    recipient: principal,
    amount: uint,
    unlock-block: uint,
    claimed: bool,
    created-at: uint
  }
)

;; Track next schedule ID
(define-data-var next-schedule-id uint u1)

;; Track total locked funds
(define-data-var total-locked uint u0)

;; Public functions

;; Create a new dividend schedule
(define-public (create-dividend-schedule (recipient principal) (amount uint) (delay-blocks uint))
  (let
    (
      (schedule-id (var-get next-schedule-id))
      (unlock-block (+ block-height delay-blocks))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (> delay-blocks u0) err-invalid-delay)
    (asserts! (>= (stx-get-balance (as-contract tx-sender)) (+ (var-get total-locked) amount)) err-insufficient-funds)
    
    ;; Store the dividend schedule
    (map-set dividend-schedules
      { schedule-id: schedule-id }
      {
        recipient: recipient,
        amount: amount,
        unlock-block: unlock-block,
        claimed: false,
        created-at: block-height
      }
    )
    
    ;; Update tracking variables
    (var-set next-schedule-id (+ schedule-id u1))
    (var-set total-locked (+ (var-get total-locked) amount))
    
    (ok schedule-id)
  )
)

;; Claim dividend (can be called by recipient or anyone after unlock time)
(define-public (claim-dividend (schedule-id uint))
  (let
    (
      (schedule (unwrap! (map-get? dividend-schedules { schedule-id: schedule-id }) err-not-found))
    )
    (asserts! (>= block-height (get unlock-block schedule)) err-not-ready)
    (asserts! (not (get claimed schedule)) err-already-claimed)
    
    ;; Mark as claimed
    (map-set dividend-schedules
      { schedule-id: schedule-id }
      (merge schedule { claimed: true })
    )
    
    ;; Update total locked amount
    (var-set total-locked (- (var-get total-locked) (get amount schedule)))
    
    ;; Transfer STX to recipient
    (as-contract (stx-transfer? (get amount schedule) tx-sender (get recipient schedule)))
  )
)

;; Batch claim multiple dividends
(define-public (claim-multiple-dividends (schedule-ids (list 10 uint)))
  (ok (map claim-dividend schedule-ids))
)

;; Owner functions

;; Fund the contract
(define-public (fund-contract (amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (stx-transfer? amount tx-sender (as-contract tx-sender))
  )
)

;; Emergency withdrawal (only unlocked funds)
(define-public (emergency-withdraw (amount uint))
  (let
    (
      (available-balance (- (stx-get-balance (as-contract tx-sender)) (var-get total-locked)))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= amount available-balance) err-insufficient-funds)
    
    (as-contract (stx-transfer? amount tx-sender contract-owner))
  )
)

;; Cancel unclaimed dividend (only before unlock time)
(define-public (cancel-dividend (schedule-id uint))
  (let
    (
      (schedule (unwrap! (map-get? dividend-schedules { schedule-id: schedule-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (< block-height (get unlock-block schedule)) err-not-ready)
    (asserts! (not (get claimed schedule)) err-already-claimed)
    
    ;; Mark as claimed to prevent future claims
    (map-set dividend-schedules
      { schedule-id: schedule-id }
      (merge schedule { claimed: true })
    )
    
    ;; Update total locked amount
    (var-set total-locked (- (var-get total-locked) (get amount schedule)))
    
    (ok true)
  )
)

;; Read-only functions

;; Get dividend schedule details
(define-read-only (get-dividend-schedule (schedule-id uint))
  (map-get? dividend-schedules { schedule-id: schedule-id })
)

;; Check if dividend is ready to claim
(define-read-only (is-dividend-ready (schedule-id uint))
  (match (map-get? dividend-schedules { schedule-id: schedule-id })
    schedule (and 
               (>= block-height (get unlock-block schedule))
               (not (get claimed schedule)))
    false
  )
)

;; Get blocks remaining until unlock
(define-read-only (blocks-until-unlock (schedule-id uint))
  (match (map-get? dividend-schedules { schedule-id: schedule-id })
    schedule (if (>= block-height (get unlock-block schedule))
               u0
               (- (get unlock-block schedule) block-height))
    u0
  )
)

;; Get contract statistics
(define-read-only (get-contract-stats)
  {
    total-locked: (var-get total-locked),
    available-balance: (- (stx-get-balance (as-contract tx-sender)) (var-get total-locked)),
    contract-balance: (stx-get-balance (as-contract tx-sender)),
    next-schedule-id: (var-get next-schedule-id)
  }
)

;; Get dividend schedule IDs for a specific recipient (check first 20 schedules)
(define-read-only (get-recipient-schedule-ids (recipient principal))
  (let
    (
      (results (list 
        (if (is-recipient-schedule-id u1 recipient) (some u1) none)
        (if (is-recipient-schedule-id u2 recipient) (some u2) none)
        (if (is-recipient-schedule-id u3 recipient) (some u3) none)
        (if (is-recipient-schedule-id u4 recipient) (some u4) none)
        (if (is-recipient-schedule-id u5 recipient) (some u5) none)
        (if (is-recipient-schedule-id u6 recipient) (some u6) none)
        (if (is-recipient-schedule-id u7 recipient) (some u7) none)
        (if (is-recipient-schedule-id u8 recipient) (some u8) none)
        (if (is-recipient-schedule-id u9 recipient) (some u9) none)
        (if (is-recipient-schedule-id u10 recipient) (some u10) none)
      ))
    )
    (filter-out-none results)
  )
)

;; Helper to filter out none values and return just the uint values
(define-private (filter-out-none (items (list 10 (optional uint))))
  (fold filter-none-helper items (list))
)

;; Helper for folding to remove none values
(define-private (filter-none-helper (item (optional uint)) (acc (list 10 uint)))
  (match item
    value (unwrap-panic (as-max-len? (append acc value) u10))
    acc
  )
)

;; Helper function to check if a schedule ID belongs to recipient
(define-private (is-recipient-schedule-id (schedule-id uint) (recipient principal))
  (match (map-get? dividend-schedules { schedule-id: schedule-id })
    schedule (is-eq (get recipient schedule) recipient)
    false
  )
)

;; Check if a specific recipient has any pending dividends
(define-read-only (has-pending-dividends (recipient principal))
  (or 
    (check-recipient-dividend-helper u1 recipient)
    (check-recipient-dividend-helper u2 recipient)
    (check-recipient-dividend-helper u3 recipient)
    (check-recipient-dividend-helper u4 recipient)
    (check-recipient-dividend-helper u5 recipient)
    (check-recipient-dividend-helper u6 recipient)
    (check-recipient-dividend-helper u7 recipient)
    (check-recipient-dividend-helper u8 recipient)
    (check-recipient-dividend-helper u9 recipient)
    (check-recipient-dividend-helper u10 recipient)
  )
)

;; Helper function to check if schedule belongs to recipient and is unclaimed
(define-private (check-recipient-dividend-helper (schedule-id uint) (recipient principal))
  (match (map-get? dividend-schedules { schedule-id: schedule-id })
    schedule (and (is-eq (get recipient schedule) recipient)
                  (not (get claimed schedule)))
    false
  )
)