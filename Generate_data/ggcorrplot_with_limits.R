#Function taken from ggcorrplot package. Limits argument is added to plot matrix elements outisde of (-1, 1) range

ggcorrplot2 <- function (corr, method = c("square", "circle"), type = c("full", 
                                                         "lower", "upper"),
          limits = c(-1, 1),
          ggtheme = ggplot2::theme_minimal, title = "", 
          show.legend = TRUE, legend.title = "Corr", show.diag = NULL, 
          colors = c("blue", "white", "red"), outline.color = "gray", 
          hc.order = FALSE, hc.method = "complete", lab = FALSE, lab_col = "black", 
          lab_size = 4, p.mat = NULL, sig.level = 0.05, insig = c("pch", 
                                                                  "blank"), 
          pch = 4, pch.col = "black", pch.cex = 5, tl.cex = 12, 
          tl.col = "black", tl.srt = 45, digits = 2, as.is = FALSE) 
{
    type <- match.arg(type)
    method <- match.arg(method)
    insig <- match.arg(insig)
    if (is.null(show.diag)) {
        if (type == "full") {
            show.diag <- TRUE
        }
        else {
            show.diag <- FALSE
        }
    }
    if (inherits(corr, "cor_mat")) {
        cor.mat <- corr
        corr <- .tibble_to_matrix(cor.mat)
        p.mat <- .tibble_to_matrix(attr(cor.mat, "pvalue"))
    }
    if (!is.matrix(corr) & !is.data.frame(corr)) {
        stop("Need a matrix or data frame!")
    }
    corr <- as.matrix(corr)
    corr <- base::round(x = corr, digits = digits)
    if (hc.order) {
        ord <- .hc_cormat_order(corr, hc.method = hc.method)
        corr <- corr[ord, ord]
        if (!is.null(p.mat)) {
            p.mat <- p.mat[ord, ord]
            p.mat <- base::round(x = p.mat, digits = digits)
        }
    }
    if (!show.diag) {
        corr <- .remove_diag(corr)
        p.mat <- .remove_diag(p.mat)
    }
    if (type == "lower") {
        corr <- .get_lower_tri(corr, show.diag)
        p.mat <- .get_lower_tri(p.mat, show.diag)
    }
    else if (type == "upper") {
        corr <- .get_upper_tri(corr, show.diag)
        p.mat <- .get_upper_tri(p.mat, show.diag)
    }
    corr <- reshape2::melt(corr, na.rm = TRUE, as.is = as.is)
    colnames(corr) <- c("Var1", "Var2", "value")
    corr$pvalue <- rep(NA, nrow(corr))
    corr$signif <- rep(NA, nrow(corr))
    if (!is.null(p.mat)) {
        p.mat <- reshape2::melt(p.mat, na.rm = TRUE)
        corr$coef <- corr$value
        corr$pvalue <- p.mat$value
        corr$signif <- as.numeric(p.mat$value <= sig.level)
        p.mat <- subset(p.mat, p.mat$value > sig.level)
        if (insig == "blank") {
            corr$value <- corr$value * corr$signif
        }
    }
    corr$abs_corr <- abs(corr$value) * 10
    p <- ggplot2::ggplot(data = corr, mapping = ggplot2::aes_string(x = "Var1", 
                                                                    y = "Var2", fill = "value"))
    if (method == "square") {
        p <- p + ggplot2::geom_tile(color = outline.color)
    }
    else if (method == "circle") {
        p <- p + ggplot2::geom_point(color = outline.color, shape = 21, 
                                     ggplot2::aes_string(size = "abs_corr")) + ggplot2::scale_size(range = c(4, 
                                                                                                             10)) + ggplot2::guides(size = "none")
    }
    p <- p + ggplot2::scale_fill_gradient2(low = colors[1], high = colors[3], 
                                           mid = colors[2], midpoint = 0, 
                                           limit = limits, space = "Lab", 
                                           name = legend.title)
    if (class(ggtheme)[[1]] == "function") {
        p <- p + ggtheme()
    }
    else if (class(ggtheme)[[1]] == "theme") {
        p <- p + ggtheme
    }
    p <- p + ggplot2::theme(axis.text.x = ggplot2::element_text(angle = tl.srt, 
                                                                vjust = 1, size = tl.cex, hjust = 1), axis.text.y = ggplot2::element_text(size = tl.cex)) + 
        ggplot2::coord_fixed()
    label <- round(x = corr[, "value"], digits = digits)
    if (!is.null(p.mat) & insig == "blank") {
        ns <- corr$pvalue > sig.level
        if (sum(ns) > 0) 
            label[ns] <- " "
    }
    if (lab) {
        p <- p + ggplot2::geom_text(mapping = ggplot2::aes_string(x = "Var1", 
                                                                  y = "Var2"), label = label, color = lab_col, size = lab_size)
    }
    if (!is.null(p.mat) & insig == "pch") {
        p <- p + ggplot2::geom_point(data = p.mat, mapping = ggplot2::aes_string(x = "Var1", 
                                                                                 y = "Var2"), shape = pch, size = pch.cex, color = pch.col)
    }
    if (title != "") {
        p <- p + ggplot2::ggtitle(title)
    }
    if (!show.legend) {
        p <- p + ggplot2::theme(legend.position = "none")
    }
    p <- p + ggcorrplot:::.no_panel()
    p
}