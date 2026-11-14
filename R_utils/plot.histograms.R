# ______________________________________________________________________________
# Aydin Karatas
# ___
# University of Southern California
# Department of Quantitative and Computational Biology
# Mooney Lab
# kinship_structure
# ___
# plot.histograms.R
# ______________________________________________________________________________


plot.histograms <- function(histograms, generations, selected = NULL,
                            faceted = FALSE) {
  grouped <- "cohort.pair" %in% names(histograms)
  degree.metric <- "degree" %in% names(histograms)
  if (degree.metric) histograms <- complete.degree.histograms(histograms)
  generations <- generations[order(generations$generation), ]
  generations$frame.label <- paste0(generations$label, " (",
                                     generations$cohort.sizes, ")")
  data <- dplyr::left_join(histograms,
                           generations[, c("generation", "frame.label")],
                           by = "generation")
  data$frame.label <- factor(data$frame.label,
                             levels = generations$frame.label, ordered = TRUE)
  data$percentage <- 100 * data$proportion
  totals <- histograms
  if (grouped) {
    keys <- c("generation", if (degree.metric) "degree" else "bin")
    totals <- dplyr::summarise(
      dplyr::group_by(histograms, dplyr::across(dplyr::all_of(keys))),
      proportion = sum(proportion), .groups = "drop")
    data$cohort.pair <- factor(data$cohort.pair,
                                levels = cohort.pair.labels())
    data <- dplyr::arrange(data, dplyr::across(dplyr::all_of(keys)),
                            cohort.pair)
    data <- dplyr::mutate(
      dplyr::group_by(data, dplyr::across(dplyr::all_of(keys))),
      ymax = cumsum(percentage), ymin = ymax - percentage)
    data <- dplyr::ungroup(data)
  }
  y.maximum <- max(1, 100 * max(totals$proportion) * 1.05)
  if (degree.metric) {
    categories <- unique(histograms$degree)
    labels <- ifelse(is.infinite(categories), "Unrelated", categories)
    data$category <- factor(data$degree, levels = categories, labels = labels)
  }
  if (!is.null(selected)) {
    data <- data[data$generation %in% selected, ]
    # animation frames must contain only the selected generation labels.
    data$frame.label <- droplevels(data$frame.label)
  }
  plot <- if (degree.metric) {
    ggplot2::ggplot(data, ggplot2::aes(x = category, y = percentage))
  } else {
    ggplot2::ggplot(data, ggplot2::aes(x = (lower + upper) / 2, y = percentage))
  }
  if (grouped) {
    data$x <- if (degree.metric) as.numeric(data$category) else
      (data$lower + data$upper) / 2
    plot$data <- data
    half.width <- if (degree.metric) 0.45 else 0.005
    # Explicit boundaries are accumulated on percentages before the transform.
    plot <- plot + ggplot2::geom_rect(ggplot2::aes(
      xmin = x - half.width, xmax = x + half.width,
      ymin = ymin, ymax = ymax, fill = cohort.pair)) +
      ggplot2::scale_fill_manual(
        values = stats::setNames(
          c("#0072B2", "#E69F00", "#009E73", "#CC79A7", "#D55E00",
            "#56B4E9"), cohort.pair.labels()),
        limits = cohort.pair.labels(), drop = FALSE, name = NULL,
        guide = ggplot2::guide_legend(nrow = 2, byrow = TRUE))
    zeros <- data[data$cohort.pair == tail(cohort.pair.labels(), 1L) &
                    data$ymax == 0, ]
  } else {
    plot <- plot + ggplot2::geom_col(
      width = if (degree.metric) 0.9 else 0.01, fill = "#247c91")
    zeros <- data[data$count == 0, ]
  }
  # gganimate cannot build a discrete layer with no rows.
  if (nrow(zeros)) {
    plot <- plot + ggplot2::geom_point(
      data = zeros, ggplot2::aes(y = 0),
      shape = 3, size = 1.2, alpha = 0.5)
  }
  plot <- plot +
    # Log1p transforms percentages while preserving exact zeros.
    ggplot2::scale_y_continuous(
      trans = scales::log1p_trans(),
      breaks = c(0, 5, 10, 15, 20, 25, 50, 75, 100),
      labels = as.character(c(0, 5, 10, 15, 20, 25, 50, 75, 100)),
      limits = c(0, y.maximum),
      expand = ggplot2::expansion(mult = c(0, 0))) +
    ggplot2::labs(
      x = if (degree.metric) "Pedigree distance (parent–child steps)" else
        "Pedigree kinship",
      y = "Percentage of active pairs\n(log1p scale)",
      caption = if (degree.metric) "+ marks zero-count categories" else
        "100 bins of width 0.01; + marks zero-count bins") +
    theme.manuscript()
  if (grouped) {
    plot <- plot + ggplot2::theme(
      legend.text = ggplot2::element_text(size = 16))
  }
  if (degree.metric) {
    plot <- plot + ggplot2::scale_x_discrete(drop = FALSE)
  } else {
    plot <- plot + ggplot2::scale_x_continuous(
      limits = c(0, 1), breaks = seq(0, 1, 0.2),
      expand = ggplot2::expansion(mult = 0))
  }
  if (faceted) {
    plot <- plot + ggplot2::facet_wrap(
      ~frame.label, ncol = 2,
      labeller = ggplot2::label_wrap_gen(width = 35))
  } else if (length(unique(data$generation)) == 1L) {
    plot <- plot + ggplot2::labs(
      title = paste(strwrap(as.character(data$frame.label[1]), width = 55),
                    collapse = "\n"))
  }
  plot
}
