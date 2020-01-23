;; Recursive Breadth-First Search
;;
;; An Implementation in Scheme for Undirected Graphs
;;
;; Taylor Alexander Brown
;; Oregon State University
;; CS 446: Networks in Computational Biology
;; Fall 2017

;; Define Some Useful Constants.
(define white 'white)
(define gray 'gray)
(define black 'black)
(define nil '())
(define infinity 'infinity)

;; Return an uninitialized graph data structure given an adjacency list
;; by adding color, predecessor, and distance attributes
;; and setting them to nil values.
(define (adjlist->graph adjacency-list)
  (map (lambda (vertex)
         (list (car vertex) nil nil nil (cadr vertex)))
       adjacency-list))

;; Graph 1
;;
;; A----C
;; | \
;; |  \
;; B----D
;;

;; Define the first adjacency list.
(define adjlist1 '((A (B C D))
                   (B (A D))
                   (C (A))
                   (D (A B))))

;; Create its uninitialized graph representation.
(define graph1 (adjlist->graph adjlist1))

;; Interpreter Input/Output:
;;
;; > graph1
;; ((a () () () (b c d))
;;  (b () () () (a d))
;;  (c () () () (a))
;;  (d () () () (a b)))

;; Graph 2
;;
;; From Cormen, et. al., p. 596
;;
;; R----S    T----U
;; |    |  / |  / |
;; |    | /  | /  |
;; V    W----X----Y
;;

;; Define the second adjacency list.
(define adjlist2 '((S (R W))
                   (R (S V))
                   (T (U W X))
                   (U (T X Y))
                   (V (R))
                   (W (S T X))
                   (X (T U W Y))
                   (Y (U X))))

;; Create its uninitialized graph representation.
(define graph2 (adjlist->graph adjlist2))

;; Interpreter Input/Output:
;;
;; > graph2
;; ((s () () () (r w))
;;  (r () () () (s v))
;;  (t () () () (u w x))
;;  (u () () () (t x y))
;;  (v () () () (r))
;;  (w () () () (s t x))
;;  (x () () () (t u w y))
;;  (y () () () (u x)))

;; Define Graph Vertex Accessors.
(define (vertex-of vertex)
  (list-ref vertex 0))
(define (color-of vertex)
  (list-ref vertex 1))
(define (predecessor-of vertex)
  (list-ref vertex 2))
(define (distance-of vertex)
  (list-ref vertex 3))
(define (neighbors-of vertex graph)
  (map (lambda (neighbor)
         (assq neighbor graph))
       (list-ref vertex 4)))

;; Define Graph Vertex Mutators.
(define (set-color! vertex color)
  (set-car! (cdr vertex) color))
(define (set-predecessor! vertex predecessor)
  (set-car! (cddr vertex) predecessor))
(define (set-distance! vertex distance)
  (set-car! (cdddr vertex) distance))

;; Define Mutable Queue Data Structure.
(define queue list)
(define-syntax push!
  (syntax-rules ()
    ((_ x Q)
     (set! Q (append Q (list x))))))
(define-syntax pop!
  (syntax-rules ()
    ((_ Q)
     (let ((x (car Q)))
       (set! Q (cdr Q))
       x))))

;; Return mutated graph G as a breadth-first tree.
;;
;; Near literal transcription of iterative BFS algorithm
;; from Cormen, et. al., p. 595.
;;
;; Assuming that first element of adjacency list is root
;; to avoid importing or implementing list processing libraries.
(define (bfs G)
  (for-each (lambda (u)                  ;
              (set-color! u white)       ; `bfs` could be simplified 
              (set-distance! u infinity) ; by moving graph intialization
              (set-predecessor! u nil))  ; outside of procedure
            (cdr G))                     ;
  (let ((s (car G)))                     ;
    (set-color! s gray)                  ;
    (set-distance! s 0)                  ;
    (set-predecessor! s nil)             ;
    (let ((Q nil))
      (push! s Q)
      (let loop () ; iteration with "named let" is just tail recursion
        (if (not (null? Q))
            (begin
              (let ((u (pop! Q)))
                (for-each (lambda (v)
                            (if (eq? (color-of v) white)
                                (begin
                                  (set-color! v gray)
                                  (set-distance! v (+ 1 (distance-of u)))
                                  (set-predecessor! v (vertex-of u))
                                  (push! v Q))))
                          (neighbors-of u G))
                (set-color! u black))
              (loop))
            G)))))

;; Interpreter Input/Output:
;;
;; > (bfs graph1)
;; ((a black () 0 (b c d))
;;  (b black a 1 (a d))
;;  (c black a 1 (a))
;;  (d black a 1 (a b)))

;; Interpreter Input/Output:
;;
;; > (bfs graph2)
;; ((s black () 0 (r w))
;;  (r black s 1 (s v))
;;  (t black w 2 (u w x))
;;  (u black t 3 (t x y))
;;  (v black r 2 (r))
;;  (w black s 1 (s t x))
;;  (x black w 2 (t u w y))
;;  (y black x 3 (u x)))


;; Now redefine `adjlist->graph` to include initialization ...


;; Return an initialized graph data structure given an adjacency list
;; by adding color, predecessor, and distance attributes
;; and setting them to initial values.
;;
;; Assuming that first element of adjacency list is root
;; to avoid importing or implementing list processing libraries.
(define (adjlist->graph adjacency-list)
  (let ((root (car adjacency-list))
        (rest (cdr adjacency-list)))
    (cons (list (car root) gray nil 0 (cadr root))
          (map (lambda (vertex)
                 (list (car vertex) white nil infinity (cadr vertex)))
               rest))))


;; ... then reinitialize graphs ...

;; Create initialized graph representation of the first adjacency list.
(define graph1 (adjlist->graph adjlist1))

;; Interpreter Input/Output:
;;
;; > graph1
;; ((a gray () 0 (b c d))
;;  (b white () infinity (a d))
;;  (c white () infinity (a))
;;  (d white () infinity (a b)))

;; Create initialized graph representation of the second adjacency list.
(define graph2 (adjlist->graph adjlist2))

;; Interpreter Input/Output:
;;
;; > graph2
;; ((s gray () 0 (r w))
;;  (r white () infinity (s v))
;;  (t white () infinity (u w x))
;;  (u white () infinity (t x y))
;;  (v white () infinity (r))
;;  (w white () infinity (s t x))
;;  (x white () infinity (t u w y))
;;  (y white () infinity (u x)))


;; ... and finally simplify `bfs`.


;; Return mutated graph G as a breadth-first tree.
;;
;; Simplified transcription of iterative BFS algorithm
;; from Cormen, et. al., p. 595.
;;
;; Assuming that first element of adjacency list is root
;; to avoid importing or implementing list processing libraries.
(define (bfs G)
  (let ((s (car G)))
    (let ((Q nil))
      (push! s Q)
      (let loop () ; iteration with "named let" is just tail recursion
        (if (not (null? Q))
            (begin
              (let ((u (pop! Q)))
                (for-each (lambda (v)
                            (if (eq? (color-of v) white)
                                (begin
                                  (set-color! v gray)
                                  (set-distance! v (+ 1 (distance-of u)))
                                  (set-predecessor! v (vertex-of u))
                                  (push! v Q))))
                          (neighbors-of u G))
                (set-color! u black))
              (loop))
            G)))))

;; Interpreter Input/Output:
;;
;; > (bfs graph1)
;; ((a black () 0 (b c d))
;;  (b black a 1 (a d))
;;  (c black a 1 (a))
;;  (d black a 1 (a b)))

;; Interpreter Input/Output:
;;
;; > (bfs graph2)
;; ((s black () 0 (r w))
;;  (r black s 1 (s v))
;;  (t black w 2 (u w x))
;;  (u black t 3 (t x y))
;;  (v black r 2 (r))
;;  (w black s 1 (s t x))
;;  (x black w 2 (t u w y))
;;  (y black x 3 (u x)))


;; Now make recursion explicit, still using mutable data.


;; Return mutated graph G as a breadth-first tree.
;;
;; Explicitly recursive algorithm.
;;
;; Requires passing initialized queue along with arguments
;; (at no cost due to tail recursion).
(define (bfs G Q)
  (if (not (null? Q))
      (let ((u (pop! Q)))
        (for-each (lambda (v)
                    (if (eq? (color-of v) white)
                        (begin
                          (set-color! v gray)
                          (set-distance! v (+ 1 (distance-of u)))
                          (set-predecessor! v (vertex-of u))
                          (push! v Q))))
                  (neighbors-of u G))
        (set-color! u black)
        (bfs G Q))
      G))

;; Interpreter Input/Output:
;;
;; > (define graph1 (adjlist->graph adjlist1))
;; > (bfs graph1 (queue (car graph1)))
;; ((a black () 0 (b c d))
;;  (b black a 1 (a d))
;;  (c black a 1 (a))
;;  (d black a 1 (a b)))

;; Interpreter Input/Output:
;;
;; > (define graph2 (adjlist->graph adjlist2))
;; > (bfs graph2 (queue (car graph2)))
;; ((s black () 0 (r w))
;;  (r black s 1 (s v))
;;  (t black w 2 (u w x))
;;  (u black t 3 (t x y))
;;  (v black r 2 (r))
;;  (w black s 1 (s t x))
;;  (x black w 2 (t u w y))
;;  (y black x 3 (u x)))


;; This demonstrates that breadth-first search can be expressed as a recursive algorithm.
;;
;; Indeed, recursion is the only control structure in Scheme: In reducing
;; the language to its minimum, its developers realized that iteration and recursion
;; are theoretically equivalent. This is also the perspective of lambda calculus.
;;
;; Tail call optimization is necessary to make it work in practice, however.
;;
;; Another discussion of recursive breadth-first search can be found on Stack Overflow:
;; https://stackoverflow.com/questions/2549541/performing-breadth-first-search-recursively?rq=1 .
;;
;; The recursive algorithm could most likely be implemented effectively in Python and other languages.


;; Becuase the recursive implementation was derived by refactoring the "iterative" version,
;; it is expected to have identical running time. This could be verified by adding a counter
;; for iterations and recursive calls.
;;
;; The implementation of the graph as an association list is highly inefficient, however
;; it could easily be replaced with a hash table.
;;
;; Compiling the source to C with the Gambit C compiler would be expected to produce
;; a highly efficient program.


;; A purely functional implementation would require the use of an immutable data structure.
;; This is possible but not necessarily easy to implement.
;;
;; For reference, see "Purely Functional Data Structures" by Chris Okasaki.


;; This program was developed using the Gambit Scheme interpreter: http://gambitscheme.org .
;;
;; To build Gambit, first obtain the source:
;;
;;     $ git clone https://github.com/gambit/gambit.git
;;
;; Then checkout the lates release and follow the instructions in INSTALL.txt:
;;
;;     $ git checkout v4.8.8
;;     $ ./configure
;;     $ make current-gsc-boot
;;     $ ./configure --enable-single-host
;;     $ make -j4 from-scratch
;;     $ make check
;;
;; Install Gambit with `sudo make install` or create a Debian package with Checkinstall
;; [https://wiki.debian.org/CheckInstall] :
;;
;;     $ sudo checkinstall
;;
;; For interactive debugging in GNU Emacs, add the following lines to .emacs:
;;
;;     (add-to-list 'load-path "/usr/local/Gambit/share/emacs/site-lisp/")
;;     (require 'gambit)
;;     (setq scheme-program-name "/usr/local/Gambit/bin/gsi -:s,d-")
;;
;; Run with `M-x run-scheme` .
;;
;; The manual can be found in /usr/local/Gambit/doc/gambit.pdf .


;; The specification of the relevant version of Scheme can be found here:
;; http://www.schemers.org/Documents/Standards/R5RS/r5rs.pdf
