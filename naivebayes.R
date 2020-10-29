## Generates the synthetic dataset for CSX46 Notebook 11: Naive Bayes

set.seed(1337)

N <- 10000 # number of protein-protein pairs
P <- 10 # number of features
LO_real <- -3.0 # actual class balance (log odds)


# vectorized function, returns same shape as X                                 
logistic <- function(x) {
    1.0/(1.0 + exp(-x))
}

# vectorized function, returns a Px2 matrix if log_odds is a P-vector
binary_probs_from_log_odds <- function(log_odds) {
    p1 <- logistic(log_odds)
    c(1.0 - p1, p1)
}

## llr = log-likelihood ratio for single feature
## loy = log-odds for class balance
## lox = log-odds for x (marginal)
single_feature_confusion_matrix <- function(llrsum, llrdiff, loy) {
    llr0 <- (llrsum - llrdiff)/2.0
    llr1 <- (llrsum + llrdiff)/2.0
    p1n <- (1.0 - exp(-llr0))/(1.0 - exp(llr1 - llr0))
    p0n <- 1.0 - p1n
    p1y <- p1n * exp(llr1)
    p0y <- 1.0 - p1y
    py <- binary_probs_from_log_odds(loy)
    c(p0n=p0n, p1n=p1n, p0y=p0y, p1y=p1y)
}

y <- sample(c(0.0, 1.0), size=N, prob=binary_probs_from_log_odds(LO_real)[1,], replace=TRUE)

posneg <- sample(c(1.0, -1.0), size=P, replace=TRUE)
norm_mean_shift <- 2.0
llrdiffs <- rnorm(n=P, mean=posneg * norm_mean_shift)
all_likelihoods <- do.call(rbind, lapply(llrdiffs, function(llrdiff) {
    single_feature_confusion_matrix(llrsum=0.0,
                                    llrdiff,
                                    LO_real)
}))

y1i <- which(y == 1)
N1 <- length(y1i)
y0i <- which(y == 0)
N0 <- length(y0i)

x <- matrix(rep(NA, N*P), ncol=P)

x <- do.call(cbind, lapply(as.list(data.frame(t(all_likelihoods))),
             function(likelihoods) {
                 p0n <- likelihoods[1]
                 p1n <- likelihoods[2]
                 p0y <- likelihoods[3]
                 p1y <- likelihoods[4]
                 xcol <- rep(NA, N)
                 xcol[y0i] <- sample(c(0,1), size=N0, replace=TRUE, prob=c(p0n, p1n))
                 xcol[y1i] <- sample(c(0,1), size=N1, replace=TRUE, prob=c(p0y, p1y))
                 xcol
             }))

xy <- cbind(x, y)

write.table(xy,
            file="naive-bayes-example.tsv",
            sep="\t",
            col.names=TRUE,
            row.names=FALSE,
            quote=FALSE)



               
