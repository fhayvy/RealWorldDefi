;; Tokenized Multi-Asset Management Platform

;; Define the contract owner
(define-data-var contract-owner principal tx-sender)

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

;; Function to transfer tokens
(define-public (transfer (to principal) (asset-id uint) (amount uint))
  (let
    (
      (sender tx-sender)
    )
    (asserts! (is-valid-asset-id asset-id) err-asset-not-found)
    (asserts! (not (is-eq to sender)) err-invalid-receiver)
    (asserts! (> amount u0) err-invalid-amount)
    (match (map-get? holdings { owner: sender, asset-id: asset-id })
      sender-balance (transfer-asset sender to asset-id amount sender-balance)
      err-insufficient-balance)
  )
)

;; Helper function to perform asset transfer
(define-private (transfer-asset (sender principal) (receiver principal) (asset-id uint) (amount uint) (sender-balance { balance: uint }))
  (let
    (
      (sender-new-balance (- (get balance sender-balance) amount))
      (receiver-balance (default-to { balance: u0 } 
        (map-get? holdings { owner: receiver, asset-id: asset-id })))
      (receiver-new-balance (+ (get balance receiver-balance) amount))
    )
    (asserts! (>= (get balance sender-balance) amount) err-insufficient-balance)
    (map-set holdings
      { owner: sender, asset-id: asset-id }
      { balance: sender-new-balance }
    )
    (map-set holdings
      { owner: receiver, asset-id: asset-id }
      { balance: receiver-new-balance }
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