;; BookStream - Monthly Digital Book Library Subscription Contract
;; Built on Stacks blockchain using Clarity

;; Contract constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-insufficient-funds (err u103))
(define-constant err-subscription-expired (err u104))
(define-constant err-unauthorized (err u105))

;; Monthly subscription fee in microSTX (1 STX = 1,000,000 microSTX)
(define-data-var monthly-fee uint u5000000) ;; 5 STX per month

;; Contract data maps
(define-map subscriptions
    { user: principal }
    {
        active: bool,
        expires-at: uint,
        started-at: uint,
        total-payments: uint
    }
)

(define-map books
    { book-id: uint }
    {
        title: (string-ascii 100),
        author: (string-ascii 50),
        genre: (string-ascii 30),
        available: bool,
        is-audiobook: bool
    }
)

(define-map user-access
    { user: principal, book-id: uint }
    { accessed-at: uint }
)

;; Data variables
(define-data-var next-book-id uint u1)
(define-data-var total-subscribers uint u0)
(define-data-var contract-balance uint u0)

;; Read-only functions

;; Get subscription details for a user
(define-read-only (get-subscription (user principal))
    (map-get? subscriptions { user: user })
)

;; Check if user has active subscription
(define-read-only (is-subscription-active (user principal))
    (match (map-get? subscriptions { user: user })
        subscription (and 
            (get active subscription)
            (> (get expires-at subscription) stacks-block-height)
        )
        false
    )
)

;; Get book details
(define-read-only (get-book (book-id uint))
    (map-get? books { book-id: book-id })
)

;; Check if user can access a specific book
(define-read-only (can-access-book (user principal) (book-id uint))
    (and
        (is-subscription-active user)
        (match (map-get? books { book-id: book-id })
            book (get available book)
            false
        )
    )
)

;; Get current monthly fee
(define-read-only (get-monthly-fee)
    (var-get monthly-fee)
)

;; Get total subscribers count
(define-read-only (get-total-subscribers)
    (var-get total-subscribers)
)

;; Get contract stats
(define-read-only (get-contract-stats)
    {
        total-subscribers: (var-get total-subscribers),
        monthly-fee: (var-get monthly-fee),
        contract-balance: (var-get contract-balance),
        total-books: (- (var-get next-book-id) u1)
    }
)

;; Public functions

;; Subscribe to BookStream service
(define-public (subscribe)
    (let
        (
            (user tx-sender)
            (fee (var-get monthly-fee))
            (expires-at (+ stacks-block-height u4320)) ;; ~30 days in blocks
        )
        ;; Check if user already has subscription
        (asserts! (is-none (map-get? subscriptions { user: user })) err-already-exists)
        
        ;; Transfer payment to contract
        (try! (stx-transfer? fee user (as-contract tx-sender)))
        
        ;; Create subscription record
        (map-set subscriptions
            { user: user }
            {
                active: true,
                expires-at: expires-at,
                started-at: stacks-block-height,
                total-payments: fee
            }
        )
        
        ;; Update contract stats
        (var-set total-subscribers (+ (var-get total-subscribers) u1))
        (var-set contract-balance (+ (var-get contract-balance) fee))
        
        (ok true)
    )
)

;; Renew subscription (monthly payment)
(define-public (renew-subscription)
    (let
        (
            (user tx-sender)
            (fee (var-get monthly-fee))
        )
        ;; Check if subscription exists
        (match (map-get? subscriptions { user: user })
            subscription
            (begin
                ;; Transfer renewal payment
                (try! (stx-transfer? fee user (as-contract tx-sender)))
                
                ;; Extend subscription by 30 days
                (let ((new-expires-at (+ (get expires-at subscription) u4320)))
                    (map-set subscriptions
                        { user: user }
                        {
                            active: true,
                            expires-at: new-expires-at,
                            started-at: (get started-at subscription),
                            total-payments: (+ (get total-payments subscription) fee)
                        }
                    )
                )
                
                ;; Update contract balance
                (var-set contract-balance (+ (var-get contract-balance) fee))
                (ok true)
            )
            err-not-found
        )
    )
)

;; Cancel subscription
(define-public (cancel-subscription)
    (let ((user tx-sender))
        (match (map-get? subscriptions { user: user })
            subscription
            (begin
                (map-set subscriptions
                    { user: user }
                    (merge subscription { active: false })
                )
                (var-set total-subscribers (- (var-get total-subscribers) u1))
                (ok true)
            )
            err-not-found
        )
    )
)

;; Access a book (record access for analytics)
(define-public (access-book (book-id uint))
    (let ((user tx-sender))
        ;; Verify user can access the book
        (asserts! (can-access-book user book-id) err-unauthorized)
        
        ;; Record access
        (map-set user-access
            { user: user, book-id: book-id }
            { accessed-at: stacks-block-height }
        )
        
        (ok true)
    )
)

;; Admin functions (only contract owner)

;; Add a new book to the library
(define-public (add-book (title (string-ascii 100)) (author (string-ascii 50)) (genre (string-ascii 30)) (is-audiobook bool))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        
        (let ((book-id (var-get next-book-id)))
            (map-set books
                { book-id: book-id }
                {
                    title: title,
                    author: author,
                    genre: genre,
                    available: true,
                    is-audiobook: is-audiobook
                }
            )
            
            (var-set next-book-id (+ book-id u1))
            (ok book-id)
        )
    )
)

;; Update book availability
(define-public (set-book-availability (book-id uint) (available bool))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        
        (match (map-get? books { book-id: book-id })
            book
            (begin
                (map-set books
                    { book-id: book-id }
                    (merge book { available: available })
                )
                (ok true)
            )
            err-not-found
        )
    )
)

;; Update monthly subscription fee
(define-public (set-monthly-fee (new-fee uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set monthly-fee new-fee)
        (ok true)
    )
)

;; Withdraw contract funds (owner only)
(define-public (withdraw-funds (amount uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (<= amount (var-get contract-balance)) err-insufficient-funds)
        
        (try! (as-contract (stx-transfer? amount tx-sender contract-owner)))
        (var-set contract-balance (- (var-get contract-balance) amount))
        (ok true)
    )
)

;; Emergency pause (disable new subscriptions)
(define-data-var contract-paused bool false)

(define-public (pause-contract)
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set contract-paused true)
        (ok true)
    )
)

(define-public (unpause-contract)
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set contract-paused false)
        (ok true)
    )
)

(define-read-only (is-contract-paused)
    (var-get contract-paused)
)