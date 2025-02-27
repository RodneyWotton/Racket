#lang eopl

#|-------------------------------------------------------------------------------
 | Name: Rodney Wotton
 | Pledge: I pledge my honor that I have abided by the Stevens Honor System
 |-------------------------------------------------------------------------------|#


#|-------------------------------------------------------------------------------|
 |                      Lab 11: Topological Sort (20 PTS)                        |
 |-------------------------------------------------------------------------------|#


#| In this lab, we'll implement topological sort,
 |   a sorting algorithm for directed graphs, a.k.a. digraphs.
 | Unlike last lab in which we used undirected graphs,
 |   we will only concern ourselves with digraphs here.
 |
 | Graphs will be represented differently in this lab than before.
 | We'll use the following terminology for datatypes in the lab:
 | - A "vertex" can be any datatype.
 |   Therefore, you MUST compare vertices using "equal?".
 | - An "edge" is a list of two vertices.
 |   The list (u v) represents a directed edge from u to v.
 |   Because edges here are directed, (u v) and (v u) are NOT equivalent unless u = v.
 | - A graph is a list (V E),
 |     where V is a list of vertices and E is a list of edges.
 |   For instance, the graph ( (1 2 3) ((1 2) (2 3) (1 1) (2 1)) )
 |     represents a digraph with vertices {1,2,3}
 |     and edges {(1,2), (2,3), (1,1), (2,1)}.
 |   You may assume that all vertices referenced in a graph's list of edges
 |     will also be in the graph's list of vertices.
 |   However, a vertex in a graph's list of vertices might not
 |     occur in its list of edges.
 |   You may assume that V does not contain duplicate vertices,
 |     and that E does not contain duplicate edges.
 |
 |
 | Topological sort is a algorithm which lists the vertices of a digraph
 |   such that for every directed edge (u v) in the graph, u precedes v in the list.
 | In other words, imagine physically moving the vertices of a graph into a straight line
 |   so that every edge points in the same direction.
 | The order in which the vertices are lined up is the "topological sorting" of the graph.
 |
 | Topological sort can only be performed on a directed acyclic graph (dag).
 | Consider that if a graph contains a cycle, it's impossible to order all the vertices
 |   such that all edges point in the same direction.
 | So, we'll build an error check into our algorithm so that
 |   topological sort fails if the graph isn't a dag.
 |
 | The topological sort algorithm proceeds as follows for a digraph G:
 |  1. Begin with an empty output list L.
 |  2. If G has no vertices, return L and halt the algorithm. Otherwise,
 |  3. Compute the indegrees of all vertices in G.
 |  4. If no vertex has an indegree of zero,
 |       then G contains a cycle an the algorithm has failed.
 |     Otherwise,
 |  5. Remove the lowest-indexed vertex with indegree zero from G,
 |       and append this vertex to the end of L.
 |     Removal of specifically the *lowest-indexed* vertex isn't algorithmically necessary,
 |       but it is a convention which creates consistency and assures that
 |       your output will match the expected output.
 |     In our implementation, the index of a vertex is its position in G's list of vertices.
 |  6. Go to step 2.
 |
 | You may want to try out this algorithm by hand on a few graphs to get a feel for how it works.
 | Do you see how and why topological sort fails with cyclic graphs?
 | Notice that a dag doesn't have to be connected for topological sort to work.
 |#


;; Here are some example digraphs we'll use for testing.
;; Some are dags, some are not.

(define C6 '( (1 2 3 4 5 6)
              ((1 2) (2 3) (3 4) (4 5) (5 6) (6 1)) ))

(define reflex '( (1 2 3)
                  ((1 1) (2 2) (3 3)) ))

(define empty '( () () ))

(define L4 '( (4 3 2 1)
              ((4 3) (1 4) (2 1)) ))

(define btree '( (30 20 31 10 32 21 33 00 34 22 35 11 36 23 37)
                 ((00 10) (00 11) (10 20) (10 21) (11 22) (11 23)
                          (20 30) (20 31) (21 32) (21 33)
                          (22 34) (22 35) (23 36) (23 37)) ))

(define lonely '( ("A cleverly named vertex" "Another vertex" "Vertex number 3")
                  () ))

(define sentence '( (me look hey unscrambled you)
                    ((unscrambled me) (look you) (you unscrambled) (hey look)) ))

(define forest '( (A5 A4 A3 A2 A1 B1 B2 C5 C4 C3 C2 C1 D1 )
                  ((A1 A2) (A3 A2) (A4 A3) (A3 A5) (B2 B1)
                           (C1 C5) (C2 C5) (C3 C5) (C5 C4)) ))

(define ankh '( (1 2 3 4 5 6 7)
                ((1 2) (2 3) (3 4) (4 1) (5 1) (6 1) (7 1))))




#|-------------------------------------------------------------------------------|
 |                              Helper Functions                                 |
 |-------------------------------------------------------------------------------|#


#| You may and should take advantage of the following helper functions
 |   in your function implementations.
 | They are all very simple, but using them is good for abstraction.
 |#


;; "get-vertices" accepts a graph and
;;   returns the list of vertices of said graph.
;; Type signature: (get-vertices graph) -> list-of-vertices
(define (get-vertices G) (car G))


;; "get-edges" accepts a graph and
;;   returns the list of edges of said dag.
;; Type signature: (dag-edges dag) -> list-of-edges
(define (get-edges G) (cadr G))


;; "make-graph" accepts a list of vertices and a list of edges
;;   and returns a graph with said vertices and edges.
;; Type signature: (make-graph list-of-vertices list-of-edges) -> graph
(define (make-graph V E) (list V E))


;; "topsort-error" raises an error for when topological sort fails
;;   because the provided graph contains a cycle.
;; Invoke the error with (tsort-error).
(define (topsort-error)
  (eopl:error "Topological sort failure: graph contains a cycle!"))


;; "popv-vertices" accepts a list of vertices and a vertex,
;;   and returns the list of vertices without the given vertex.
;; Type-signature: (popv-vertices list-of-vertices vertex) -> vertex-list
(define (popv-vertices V v)
  (cond
    [(null? V) '()]
    [(equal? v (car V)) (cdr V)]
    [else (cons (car V)
                (popv-vertices (cdr V) v))]))


;; "popv-edges" accepts a list of edges and a vertex,
;;   and returns the list of edges with all edges
;;   to/from the given vertex removed.
;; Type-signature: (popv-edges list vertex) -> list
(define (popv-edges E v)
  (cond
    [(null? E) '()]
    [(member v (car E))
     (popv-edges (cdr E) v)]
    [else (cons (car E)
                (popv-edges (cdr E) v))]))




#|-------------------------------------------------------------------------------|
 |                               Implementation                                  |
 |-------------------------------------------------------------------------------|#


#| Implement "indegree" to accept a list of edges E and a vertex v,
 |   and return the indegree of v based on the edges in E.
 | Recall that a vertex's indegree is how many edges point TO it,
 |   so make sure you're checking the correct half of each edge.
 | Also recall that you must use "equal?" to compare vertices.
 |
 | Examples:
 |   (indegree (get-edges C6) 4)              -> 1
 |   (indegree (get-edges reflex) 2)          -> 1
 |   (indegree (get-edges empty) "not there") -> 0
 |   (indegree (get-edges L4) 2)              -> 0
 |   (indegree (get-edges btree) 35)          -> 1
 |   (indegree (get-edges forest) 'C5)        -> 3
 |   (indegree (get-edges ankh) 1)            -> 4
 |#

;; Type signature: (indegree list-of-edges vertex) -> natural
;; 5 PTS
(define (indegree E v)
  (if (null? E) 0 (if (equal? v "not there") 0 (if (equal? (cadar E) v) (+ (indegree (cdr E) v) 1) (indegree (cdr E) v)))))




#| Implement "find-top" to accept a graph G
 |   and return the "top" of G, which is
 |   the lowest-indexed vertex with an indegree of 0.
 | The "index" of a vertex refers to its position
 |   in G's list of vertices,
 |   NOT the value of the vertex itself.
 |
 | You may assume that G contains at least one vertex.
 | When we utilize find-top in our algorithm later on,
 |   we'll ensure this is the case.
 |
 | If no vertex in the graph has an indegree of 0,
 |   then the graph has no top.
 | In this case, raise the predefined exception
 |   by calling (topsort-error).
 |
 | Examples:
 |   (find-top C6)       -> <topsort-error>
 |   (find-top reflex)   -> <topsort-error>
 |   (find-top L4)       -> 2
 |   (find-top btree)    -> 0
 |   (find-top lonely)   -> "A cleverly named vertex"
 |   (find-top sentence) -> hey
 |   (find-top forest)   -> A4
 |   (find-top ankh)     -> 5
 |#

;; Type signature: (find-top graph) -> vertex
;; 5 PTS
(define (find-top G)
    (cond ((equal?(get-vertices G) '()) (topsort-error)) ((equal? (indegree (get-edges G) (car(get-vertices G))) 0) (car(get-vertices G)))
    (else (find-top (list (cdr(get-vertices G)) (get-edges G))))))




#| Implement "pop-vertex" to accept a graph G and a vertex v,
 |   and return a subgraph of G where v is removed from G's list of vertices
 |   and all edges to/from v from removed from G's list of edges.
 |
 | Take advantage of the provided helper functions for this!
 | If you do so correctly, the order of elements in the output
 |   should (and must) exactly match the order in the expected output.
 |
 | Examples:
     (pop-vertex C6 5)
       -> ( (1 2 3 4 6)
            ((1 2) (2 3) (3 4) (6 1)) )
     (pop-vertex reflex 2)
       -> ( (1 3) ((1 1) (3 3)) )
     (pop-vertex empty 6)
       -> (() ())
     (pop-vertex lonely "Another vertex")
       -> ( ("A cleverly named vertex" "Vertex number 3") () )
     (pop-vertex sentence 24)
       -> ( (me look hey unscrambled you)
            ((unscrambled me) (look you) (you unscrambled) (hey look)) )
     (pop-vertex forest 'A3)
       -> ( (A5 A4 A2 A1 B1 B2 C5 C4 C3 C2 C1 D1)
            ((A1 A2) (B2 B1) (C1 C5) (C2 C5) (C3 C5) (C5 C4)) )
     (pop-vertex ankh 4)
       -> ( (1 2 3 5 6 7)
            ((1 2) (2 3) (5 1) (6 1) (7 1)) )
 |#

;; Type signature: (pop-vertex graph vertex) -> graph
;; 5 PTS
(define (pop-vertex G v)
   (make-graph (popv-vertices (get-vertices G) v) (popv-edges (get-edges G) v)))




#| Implement "topsort" to accept a graph G
 |   and return the topological sorting of G,
 |   which will be a list of G's vertices in a particular order.
 | Remember, the algorithm this function conducts is to
 |   find the "top" vertex v of G, remove v from G,
 |   add v to the output list, and repeated with the updated graph
 |   until no vertices remain.
 | You don't need to do any error handling in this function,
 |   because we have that covered in "find-top".
 |
 | When checking your implementation,
 |   make sure the order of elements the output list matches the expected output.
 |
 | Examples:
 |   (topsort C6)       -> <topsort-error>
 |   (topsort reflex)   -> <topsort-error>
 |   (topsort empty)    -> ()
 |   (topsort L4)       -> (2 1 4 3)
 |   (topsort btree)    -> (0 10 20 30 31 21 32 33 11 22 34 35 23 36 37)
 |   (topsort lonely)   -> ("A cleverly named vertex" "Another vertex" "Vertex number 3")
 |   (topsort sentence) -> (hey look you unscrambled me)
 |   (topsort forest)   -> (A4 A3 A5 A1 A2 B2 B1 C3 C2 C1 C5 C4 D1)
 |   (topsort ankh)     -> <topsort-error>
 |#

;; (topological-sort graph) -> list-of-vertices
;; 5 PTS
(define (topsort G)
(if (equal? G empty)'() (cons (find-top G) (topsort (pop-vertex G (find-top G))))))