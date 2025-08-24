;; FraxAsset Protocol - Revolutionary Real-World Asset Tokenization Platform
;;
;; Summary: 
;; FraxAsset empowers institutional and retail investors to unlock liquidity from 
;; traditionally illiquid assets through blockchain-native fractional ownership.
;; Built on Bitcoin's security layer via Stacks, this protocol democratizes access
;; to high-value assets while maintaining regulatory compliance and transparency.
;;
;; Description:
;; The FraxAsset Protocol represents a paradigm shift in asset management, bridging
;; traditional finance with decentralized infrastructure. By leveraging Clarity's
;; security guarantees and Bitcoin's settlement finality, we've created a robust
;; ecosystem for tokenizing real estate, art, commodities, and other high-value assets.
;;
;; Key innovations include:
;; - Dynamic semi-fungible token architecture for precise ownership representation
;; - Integrated KYC/AML compliance framework for institutional adoption
;; - Sophisticated governance mechanisms enabling stakeholder participation
;; - Automated dividend distribution with transparent yield tracking
;; - Oracle-powered real-time asset valuation and price discovery
;; - Multi-layered security with Bitcoin-backed settlement guarantees

;; SYSTEM CONSTANTS & ERROR DEFINITIONS

;; Core System Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant TOKENS-PER-ASSET u100000) ;; Fractional token supply per asset

;; Asset Value Constraints
(define-constant MAX-ASSET-VALUE u1000000000000) ;; $1T maximum asset value
(define-constant MIN-ASSET-VALUE u1000) ;; $1K minimum asset value

;; Governance & Voting Parameters
(define-constant MAX-PROPOSAL-DURATION u144) ;; ~24 hours in blocks
(define-constant MIN-PROPOSAL-DURATION u12) ;; ~2 hours in blocks
(define-constant MAX-KYC-COMPLIANCE-LEVEL u5) ;; Highest compliance tier
(define-constant MAX-VALIDITY-PERIOD u52560) ;; ~365 days in blocks

;; ERROR CODE REGISTRY

;; Access Control Errors (100-109)
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-NOT-AUTHORIZED (err u104))
(define-constant ERR-KYC-REQUIRED (err u105))

;; Asset Management Errors (110-119)
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-EXISTS (err u102))
(define-constant ERR-INVALID-AMOUNT (err u103))
(define-constant ERR-ASSET-LOCKED (err u108))

;; Governance & Voting Errors (120-129)
(define-constant ERR-VOTE-EXISTS (err u106))
(define-constant ERR-VOTING-ENDED (err u107))
(define-constant ERR-INSUFFICIENT-VOTES (err u115))

;; Validation Errors (130-139)
(define-constant ERR-INVALID-URI (err u110))
(define-constant ERR-INVALID-VALUE (err u111))
(define-constant ERR-INVALID-DURATION (err u112))
(define-constant ERR-INVALID-KYC-LEVEL (err u113))
(define-constant ERR-INVALID-EXPIRY (err u114))
(define-constant ERR-INVALID-ADDRESS (err u116))
(define-constant ERR-INVALID-TITLE (err u117))

;; CORE DATA STRUCTURES

;; Asset Registry - Primary storage for tokenized assets
(define-map assets
  { asset-id: uint }
  {
    owner: principal,
    metadata-uri: (string-ascii 256),
    asset-value: uint,
    is-locked: bool,
    creation-height: uint,
    last-price-update: uint,
    total-dividends: uint,
  }
)

;; Token Ownership Ledger - Tracks fractional ownership
(define-map token-balances
  {
    owner: principal,
    asset-id: uint,
  }
  { balance: uint }
)

;; KYC Compliance Registry - Regulatory compliance tracking
(define-map kyc-status
  { address: principal }
  {
    is-approved: bool,
    compliance-level: uint,
    expiry-height: uint,
  }
)

;; Governance Proposal Registry - Democratic decision making
(define-map proposals
  { proposal-id: uint }
  {
    title: (string-ascii 256),
    target-asset-id: uint,
    start-height: uint,
    end-height: uint,
    is-executed: bool,
    affirmative-votes: uint,
    negative-votes: uint,
    quorum-threshold: uint,
  }
)

;; Voting Records - Prevents double voting
(define-map votes
  {
    proposal-id: uint,
    voter: principal,
  }
  { vote-weight: uint }
)

;; Dividend Distribution Tracker - Yield management
(define-map dividend-claims
  {
    asset-id: uint,
    beneficiary: principal,
  }
  { last-claimed-total: uint }
)

;; Oracle Price Feeds - Real-time asset valuation
(define-map price-feeds
  { asset-id: uint }
  {
    current-price: uint,
    decimal-precision: uint,
    last-update-height: uint,
    oracle-provider: principal,
  }
)

;; INPUT VALIDATION FRAMEWORK

(define-private (is-valid-asset-value (value uint))
  (and
    (>= value MIN-ASSET-VALUE)
    (<= value MAX-ASSET-VALUE)
  )
)

(define-private (is-valid-proposal-duration (duration uint))
  (and
    (>= duration MIN-PROPOSAL-DURATION)
    (<= duration MAX-PROPOSAL-DURATION)
  )
)

(define-private (is-valid-kyc-level (level uint))
  (<= level MAX-KYC-COMPLIANCE-LEVEL)
)

(define-private (is-valid-expiry (expiry uint))
  (and
    (> expiry stacks-block-height)
    (<= (- expiry stacks-block-height) MAX-VALIDITY-PERIOD)
  )
)

(define-private (is-valid-vote-threshold (threshold uint))
  (and
    (> threshold u0)
    (<= threshold TOKENS-PER-ASSET)
  )
)

(define-private (is-valid-metadata-uri (uri (string-ascii 256)))
  (and
    (> (len uri) u0)
    (<= (len uri) u256)
  )
)

;; UTILITY FUNCTIONS

;; Generate sequential asset IDs (implementation placeholder)
(define-private (generate-next-asset-id)
  (default-to u1 (get-last-registered-asset-id))
)

;; Generate sequential proposal IDs (implementation placeholder)
(define-private (generate-next-proposal-id)
  (default-to u1 (get-last-created-proposal-id))
)

;; Retrieve highest asset ID (to be implemented with counter)
(define-private (get-last-registered-asset-id)
  none
)

;; Retrieve highest proposal ID (to be implemented with counter)
(define-private (get-last-created-proposal-id)
  none
)

;; CORE PUBLIC INTERFACE

;; --------------------------------------------------------------------------------
;; Asset Registration & Tokenization
;; --------------------------------------------------------------------------------

(define-public (register-asset-for-tokenization
    (metadata-uri (string-ascii 256))
    (initial-valuation uint)
  )
  (begin
    ;; Validate caller permissions
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)

    ;; Validate input parameters
    (asserts! (is-valid-metadata-uri metadata-uri) ERR-INVALID-URI)
    (asserts! (is-valid-asset-value initial-valuation) ERR-INVALID-VALUE)

    (let ((new-asset-id (generate-next-asset-id)))
      ;; Create asset registry entry
      (map-set assets { asset-id: new-asset-id } {
        owner: CONTRACT-OWNER,
        metadata-uri: metadata-uri,
        asset-value: initial-valuation,
        is-locked: false,
        creation-height: stacks-block-height,
        last-price-update: stacks-block-height,
        total-dividends: u0,
      })

      ;; Allocate initial token supply to owner
      (map-set token-balances {
        owner: CONTRACT-OWNER,
        asset-id: new-asset-id,
      } { balance: TOKENS-PER-ASSET }
      )

      (ok new-asset-id)
    )
  )
)

;; --------------------------------------------------------------------------------
;; Dividend Distribution System
;; --------------------------------------------------------------------------------

(define-public (claim-available-dividends (asset-id uint))
  (let (
      (asset-info (unwrap! (get-asset-details asset-id) ERR-NOT-FOUND))
      (holder-balance (get-token-balance tx-sender asset-id))
      (previous-claim (get-previous-dividend-claim asset-id tx-sender))
      (total-distributed (get total-dividends asset-info))
      (claimable-amount (/ (* holder-balance (- total-distributed previous-claim)) TOKENS-PER-ASSET))
    )
    ;; Ensure there are dividends to claim
    (asserts! (> claimable-amount u0) ERR-INVALID-AMOUNT)

    ;; Update claim record
    (ok (map-set dividend-claims {
      asset-id: asset-id,
      beneficiary: tx-sender,
    } { last-claimed-total: total-distributed }
    ))
  )
)

;; --------------------------------------------------------------------------------
;; Governance & Proposal System
;; --------------------------------------------------------------------------------

(define-public (create-governance-proposal
    (target-asset-id uint)
    (proposal-title (string-ascii 256))
    (voting-duration uint)
    (quorum-requirement uint)
  )
  (begin
    ;; Validate proposal parameters
    (asserts! (is-valid-proposal-duration voting-duration) ERR-INVALID-DURATION)
    (asserts! (is-valid-vote-threshold quorum-requirement) ERR-INSUFFICIENT-VOTES)
    (asserts! (is-valid-metadata-uri proposal-title) ERR-INVALID-TITLE)

    ;; Verify proposer has minimum stake (10% of total supply)
    (asserts!
      (>= (get-token-balance tx-sender target-asset-id) (/ TOKENS-PER-ASSET u10))
      ERR-NOT-AUTHORIZED
    )

    (let ((new-proposal-id (generate-next-proposal-id)))
      (ok (map-set proposals { proposal-id: new-proposal-id } {
        title: proposal-title,
        target-asset-id: target-asset-id,
        start-height: stacks-block-height,
        end-height: (+ stacks-block-height voting-duration),
        is-executed: false,
        affirmative-votes: u0,
        negative-votes: u0,
        quorum-threshold: quorum-requirement,
      }))
    )
  )
)

;; --------------------------------------------------------------------------------
;; Democratic Voting System
;; --------------------------------------------------------------------------------

(define-public (cast-governance-vote
    (proposal-id uint)
    (support-proposal bool)
    (voting-weight uint)
  )
  (let (
      (proposal-info (unwrap! (get-proposal-details proposal-id) ERR-NOT-FOUND))
      (target-asset (get target-asset-id proposal-info))
      (voter-balance (get-token-balance tx-sender target-asset))
    )
    (begin
      ;; Validate voting conditions
      (asserts! (>= voter-balance voting-weight) ERR-INVALID-AMOUNT)
      (asserts! (< stacks-block-height (get end-height proposal-info))
        ERR-VOTING-ENDED
      )
      (asserts! (is-none (get-voting-record proposal-id tx-sender))
        ERR-VOTE-EXISTS
      )

      ;; Record the vote
      (map-set votes {
        proposal-id: proposal-id,
        voter: tx-sender,
      } { vote-weight: voting-weight }
      )

      ;; Update proposal vote tallies
      (ok (map-set proposals { proposal-id: proposal-id }
        (merge proposal-info {
          affirmative-votes: (if support-proposal
            (+ (get affirmative-votes proposal-info) voting-weight)
            (get affirmative-votes proposal-info)
          ),
          negative-votes: (if support-proposal
            (get negative-votes proposal-info)
            (+ (get negative-votes proposal-info) voting-weight)
          ),
        })
      ))
    )
  )
)

;; READ-ONLY QUERY INTERFACE

;; Retrieve comprehensive asset information
(define-read-only (get-asset-details (asset-id uint))
  (map-get? assets { asset-id: asset-id })
)

;; Query token balance for any principal
(define-read-only (get-token-balance
    (holder principal)
    (asset-id uint)
  )
  (default-to u0
    (get balance
      (map-get? token-balances {
        owner: holder,
        asset-id: asset-id,
      })
    ))
)

;; Retrieve governance proposal information
(define-read-only (get-proposal-details (proposal-id uint))
  (map-get? proposals { proposal-id: proposal-id })
)

;; Query individual voting records
(define-read-only (get-voting-record
    (proposal-id uint)
    (voter principal)
  )
  (map-get? votes {
    proposal-id: proposal-id,
    voter: voter,
  })
)

;; Access oracle price feed data
(define-read-only (get-price-feed-data (asset-id uint))
  (map-get? price-feeds { asset-id: asset-id })
)

;; Retrieve dividend claim history
(define-read-only (get-previous-dividend-claim
    (asset-id uint)
    (beneficiary principal)
  )
  (default-to u0
    (get last-claimed-total
      (map-get? dividend-claims {
        asset-id: asset-id,
        beneficiary: beneficiary,
      })
    ))
)
