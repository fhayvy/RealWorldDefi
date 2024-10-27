;; Tokenized Multi-Asset Management Platform

;; Define the contract owner
(define-data-var contract-owner principal tx-sender)

(define-trait token
  (
    (is-valid-asset-id (uint) (response bool uint))
    (get-balance (principal uint) (response {balance: uint} uint))
    (approve (principal uint uint) (response bool uint))
    (transfer-from (principal principal uint uint) (response bool uint))
  )
)

;; Define the asset structure
(define-map assets
  { asset-id: uint }
  {
    name: (string-ascii 64),
    type: (string-ascii 32),
    total-supply: uint,
    price: uint
  }
)

;; Define ownership structure
(define-map holdings
  { owner: principal, asset-id: uint }
  { balance: uint }
)

;; Define approval structure
(define-map approvals
  { owner: principal, spender: principal, asset-id: uint }
  { amount: uint }
)

;; Define error constants
(define-constant err-unauthorized (err u100))
(define-constant err-asset-exists (err u101))
(define-constant err-asset-not-found (err u102))
(define-constant err-insufficient-balance (err u103))
(define-constant err-invalid-name (err u104))
(define-constant err-invalid-type (err u105))
(define-constant err-invalid-supply (err u106))
(define-constant err-invalid-price (err u107))
(define-constant err-invalid-receiver (err u108))
(define-constant err-invalid-amount (err u109))
(define-constant err-not-approved (err u110))
(define-constant err-invalid-spender (err u111))

;; Counter for asset IDs
(define-data-var asset-id-nonce uint u0)

;; Function to create a new asset
(define-public (create-asset (name (string-ascii 64)) (type (string-ascii 32)) (total-supply uint) (price uint))
  (let
    (
      (asset-id (+ (var-get asset-id-nonce) u1))
    )
    (asserts! (is-eq tx-sender (var-get contract-owner)) err-unauthorized)
    (asserts! (is-none (map-get? assets { asset-id: asset-id })) err-asset-exists)
    ;; Input validation
    (asserts! (> (len name) u0) err-invalid-name)
    (asserts! (> (len type) u0) err-invalid-type)
    (asserts! (> total-supply u0) err-invalid-supply)
    (asserts! (> price u0) err-invalid-price)
    (map-set assets
      { asset-id: asset-id }
      { name: name, type: type, total-supply: total-supply, price: price }
    )
    (map-set holdings
      { owner: (var-get contract-owner), asset-id: asset-id }
      { balance: total-supply }
    )
    (var-set asset-id-nonce asset-id)
    (ok asset-id)
  )
)

;; Function to validate asset-id
(define-read-only (is-valid-asset-id (asset-id uint))
  (is-some (map-get? assets { asset-id: asset-id }))
)

;; Function to approve a spender
(define-public (approve (spender principal) (asset-id uint) (amount uint))
  (let
    (
      (sender tx-sender)
    )
    (asserts! (is-valid-asset-id asset-id) err-asset-not-found)
    (asserts! (not (is-eq spender sender)) err-invalid-spender)
    (asserts! (>= amount u0) err-invalid-amount)
    (map-set approvals
      { owner: sender, spender: spender, asset-id: asset-id }
      { amount: amount }
    )
    (ok true)
  )
)

;; Function to get approved amount
(define-read-only (get-approved-amount (owner principal) (spender principal) (asset-id uint))
  (default-to { amount: u0 }
    (map-get? approvals { owner: owner, spender: spender, asset-id: asset-id })
  )
)

;; Function to transfer tokens
(define-public (transfer (to principal) (asset-id uint) (amount uint))
  (let
    (
      (sender tx-sender)
    )
    (asserts! (is-valid-asset-id asset-id) err-asset-not-found)
    (asserts! (not (is-eq to sender)) err-invalid-receiver)
    (asserts! (> amount u0) err-invalid-amount)
    (transfer-asset sender to asset-id amount)
  )
)

;; Function to transfer tokens on behalf of another user
(define-public (transfer-from (from principal) (to principal) (asset-id uint) (amount uint))
  (let
    (
      (sender tx-sender)
      (approved-amount (get amount (get-approved-amount from sender asset-id)))
    )
    (asserts! (is-valid-asset-id asset-id) err-asset-not-found)
    (asserts! (not (is-eq to from)) err-invalid-receiver)
    (asserts! (>= approved-amount amount) err-not-approved)
    (asserts! (> amount u0) err-invalid-amount)
    (map-set approvals
      { owner: from, spender: sender, asset-id: asset-id }
      { amount: (- approved-amount amount) }
    )
    (transfer-asset from to asset-id amount)
  )
)

;; Helper function to perform asset transfer
(define-private (transfer-asset (from principal) (to principal) (asset-id uint) (amount uint))
  (let
    (
      (sender-balance (get balance (default-to { balance: u0 } (map-get? holdings { owner: from, asset-id: asset-id }))))
      (receiver-balance (get balance (default-to { balance: u0 } (map-get? holdings { owner: to, asset-id: asset-id }))))
    )
    (asserts! (>= sender-balance amount) err-insufficient-balance)
    (map-set holdings
      { owner: from, asset-id: asset-id }
      { balance: (- sender-balance amount) }
    )
    (map-set holdings
      { owner: to, asset-id: asset-id }
      { balance: (+ receiver-balance amount) }
    )
    (ok true)
  )
)

;; Function to get asset details
(define-read-only (get-asset-details (asset-id uint))
  (map-get? assets { asset-id: asset-id })
)

;; Function to get user balance for an asset
(define-read-only (get-balance (owner principal) (asset-id uint))
  (default-to { balance: u0 } (map-get? holdings { owner: owner, asset-id: asset-id }))
)

;; Function to change contract owner
(define-public (set-contract-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) err-unauthorized)
    (asserts! (not (is-eq new-owner (var-get contract-owner))) err-unauthorized)
    (ok (var-set contract-owner new-owner))
  )
)