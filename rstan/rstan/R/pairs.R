# Part of the rstan package for statistical analysis via Markov Chain Monte Carlo
# Copyright (C) 2013 Stan Development Team
# Copyright (C) 1995-2012 The R Core Team
# Some parts  Copyright (C) 1999 Dr. Jens Oehlschlaegel-Akiyoshi
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 3
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

pairs.stanfit <-
  function (x, labels = NULL, panel = NULL, ..., 
            lower.panel = NULL, upper.panel = NULL, diag.panel = NULL, 
            text.panel = NULL, label.pos = 0.5 + has.diag/3, 
            cex.labels = NULL, font.labels = 1, row1attop = TRUE, gap = 1, 
            pars = NULL, condition = NULL) {
    
    if(is.null(pars)) pars <- dimnames(x)[[3]]
    arr <- extract(x, pars = pars, permuted = FALSE)
    sims <- nrow(arr)
    chains <- ncol(arr)
    
    if(is.list(condition)) {
      if(length(condition) != 2) stop("if a list, 'condition' must be of length 2")
      arr <- arr[,c(condition[[1]], condition[[2]]),,drop = FALSE]
      k <- length(condition[[1]])
      mark <- c(rep(TRUE, sims * k), rep(FALSE, sims * (chains - k)))
    }
    else if(is.logical(condition)) {
      stopifnot(length(condition) == (sims * chains))
      mark <- !condition
    }
    else if(is.character(condition)) {
      condition <- match.arg(condition, several.ok = FALSE,
                             choices = c("accept_stat__", "stepsize__", "treedepth__", 
                                         "n_leapfrog__", "n_divergent__"))
      mark <- sapply(get_sampler_params(x), FUN = function(y) {
        tail(y[,condition], sims)
      })
      if(condition == "n_divergent__") mark <- as.logical(mark)
      else mark <- c(mark) >= median(mark)
    }
    else if(!is.null(condition)) {
      if(all(condition == as.integer(condition))) {
        arr <- arr[,condition,,drop = FALSE]
        k <- ncol(arr) %/% 2
        mark <- c(rep(FALSE, sims * k), rep(TRUE, sims * (chains - k)))
      }
      else if(condition > 0 && condition < 1) {
        mark <- rep(1:sims > (condition * sims), times = chains)
      }
      else stop("'condition' must be an integer (vector) or a number between 0 and 1 exclusive")
    }
    else {
      k <- ncol(arr) %/% 2
      mark <- c(rep(FALSE, sims * k), rep(TRUE, sims * (chains - k)))
    }
    
    x <- apply(arr, MARGIN = "parameters", FUN = function(y) y)
    
    if(is.null(lower.panel)) {
      if(!is.null(panel)) lower.panel <- panel
      else lower.panel <- function(x,y, ...) {
        dots <- list(...)
        dots$x <- x[!mark]
        dots$y <- y[!mark]
        if(is.null(dots$nrpoints)) dots$nrpoints <- 0
        dots$add <- TRUE
        do.call(smoothScatter, args = dots)
      }
    }
    if(is.null(upper.panel)) {
      if(!is.null(panel)) upper.panel <- panel
      else upper.panel <- function(x,y, ...) {
        dots <- list(...)
        dots$x <- x[mark]
        dots$y <- y[mark]
        if(is.null(dots$nrpoints)) dots$nrpoints <- 0
        dots$add <- TRUE
        do.call(smoothScatter, args = dots)
      }
    }
    if(is.null(diag.panel)) diag.panel <- function(x, ...) {
        usr <- par("usr"); on.exit(par(usr))
        par(usr = c(usr[1:2], 0, 1.5) )
        h <- hist(x, plot = FALSE)
        breaks <- h$breaks; nB <- length(breaks)
        y <- h$counts; y <- y/max(y)
        rect(breaks[-nB], 0, breaks[-1], y, col="cyan", ...)
    }
    if(is.null(panel)) panel <- points
    
    if(is.null(text.panel)) textPanel <- function(x = 0.5, y = 0.5, txt, cex, font) {
      text(x,y, txt, cex = cex, font = font)
    }
    else textPanel <- text.panel
    has.diag <- TRUE
    if(is.null(labels)) labels <- colnames(x)

    mc <- match.call(expand.dots = FALSE)
    mc[1] <- call("pairs")
    mc$x <- x
    mc$labels <- labels
    mc$panel <- panel
    mc$lower.panel <- lower.panel
    mc$upper.panel <- upper.panel
    mc$diag.panel <- diag.panel
    mc$text.panel <- textPanel
    mc$condition <- NULL
    mc$pars <- NULL
    eval(mc)
  }
