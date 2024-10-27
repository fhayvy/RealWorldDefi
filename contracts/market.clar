;; marketplace.clar
;; Asset Marketplace Contract

;; Import the token trait
(use-trait token-trait .token-trait.token-trait)

;; Define the contract owner
(define-data-var contract-owner principal tx-sender)

;; Define token contract principal
(define-data-var token-contract-principal principal 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.token)

;; Define listing structure
(define-map listings
  { listing-id: uint }
  {
    seller: principal,
    asset-id: uint,
    amount: uint,
    price-per-token: uint,
    active: bool
  }
)

;; Counter for listing IDs
(define-data-var listing-id-nonce uint u0)

;; Define error constants
(define-constant err-unauthorized (err u200))
(define-constant err-invalid-listing (err u201))
(define-constant err-listing-not-found (err u202))
(define-constant err-listing-not-active (err u203))
(define-constant err-insufficient-funds (err u204))
(define-constant err-invalid-price (err u205))
(define-constant err-invalid-amount (err u206))
(define-constant err-not-seller (err u207))
(define-constant err-token-contract-error (err u208))

;; Helper function to get balance with default
(define-private (get-balance-or-default (token <token-trait>) (owner principal) (asset-id uint))
  (match (contract-call? token get-balance owner asset-id)
    success (get balance success)
    error u0)
)

;; Function to update token contract principal
(define-public (set-token-contract (new-contract principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) err-unauthorized)
    (ok (var-set token-contract-principal new-contract))
  )
)

;; Function to create a new listing
(define-public (create-listing (token <token-trait>) (asset-id uint) (amount uint) (price-per-token uint))
  (let
    (
      (listing-id (+ (var-get listing-id-nonce) u1))
      (seller tx-sender)
      (seller-balance (get-balance-or-default token seller asset-id))
      (asset-valid (unwrap! (contract-call? token is-valid-asset-id asset-id) err-invalid-listing))
    )
    ;; Input validation
    (asserts! asset-valid err-invalid-listing)
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (> price-per-token u0) err-invalid-price)
    (asserts! (>= seller-balance amount) err-insufficient-funds)
    
    ;; Create listing
    (map-set listings
      { listing-id: listing-id }
      {
        seller: seller,
        asset-id: asset-id,
        amount: amount,
        price-per-token: price-per-token,
        active: true
      }
    )
    
    ;; Approve marketplace contract to transfer tokens
    (try! (contract-call? token approve (as-contract tx-sender) asset-id amount))
    
    (var-set listing-id-nonce listing-id)
    (ok listing-id)
  )
)

;; Function to cancel a listing
(define-public (cancel-listing (token <token-trait>) (listing-id uint))
  (let
    (
      (listing (unwrap! (map-get? listings { listing-id: listing-id }) err-listing-not-found))
      (seller tx-sender)
    )
    ;; Verify sender is the seller
    (asserts! (is-eq (get seller listing) seller) err-not-seller)
    ;; Verify listing is active
    (asserts! (get active listing) err-listing-not-active)
    
    ;; Update listing status
    (map-set listings
      { listing-id: listing-id }
      (merge listing { active: false })
    )
    
    ;; Remove approval
    (try! (contract-call? token approve (as-contract tx-sender) (get asset-id listing) u0))
    
    (ok true)
  )
)

;; Function to purchase from a listing
(define-public (purchase-listing (token <token-trait>) (listing-id uint) (amount uint))
  (let
    (
      (listing (unwrap! (map-get? listings { listing-id: listing-id }) err-listing-not-found))
      (buyer tx-sender)
      (total-price (* amount (get price-per-token listing)))
    )
    ;; Verify listing is active and amount is valid
    (asserts! (get active listing) err-listing-not-active)
    (asserts! (<= amount (get amount listing)) err-invalid-amount)
    
    ;; Transfer tokens from seller to buyer
    (try! (contract-call? token transfer-from 
            (get seller listing) 
            buyer
            (get asset-id listing)
            amount))
    
    ;; Transfer STX payment from buyer to seller
    (try! (stx-transfer? total-price buyer (get seller listing)))
    
    ;; Update listing amount or deactivate if fully purchased
    (map-set listings
      { listing-id: listing-id }
      (merge listing {
        amount: (- (get amount listing) amount),
        active: (> (- (get amount listing) amount) u0)
      })
    )
    
    (ok true)
  )
)

;; Read-only functions

;; Function to get listing details
(define-read-only (get-listing-details (listing-id uint))
  (map-get? listings { listing-id: listing-id })
)

;; Function to check if listing is active
(define-read-only (is-listing-active (listing-id uint))
  (match (map-get? listings { listing-id: listing-id })
    some-listing (ok (get active some-listing))
    (ok false)
  )
)



;; Function to get current token contract principal
(define-read-only (get-token-contract)
  (ok (var-get token-contract-principal))
)

;; Function to change contract owner
(define-public (set-contract-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) err-unauthorized)
    (asserts! (not (is-eq new-owner (var-get contract-owner))) err-unauthorized)
    (ok (var-set contract-owner new-owner))
  )
)
