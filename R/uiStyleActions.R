## playwith: interactive plots in R using GTK+
##
## Copyright (c) 2007 Felix Andrews <felix@nfrac.org>
## GPL version 2 or newer

createStyleActions <- function(playState, manager)
{
    ## TODO: use real GtkAction s
    ## add custom items to style submenus
    do.style_handler <- function(widget, theme) {
        playDevSet(playState)
        eval(theme, list(playState = playState), globalenv())
        playReplot(playState)
    }
    ## style shortcuts
    ssMenu <- manager$getWidget("/MenuBar/StyleMenu/ShortcutsMenu")
    if (!is.null(ssMenu)) {
        ssMenu <- ssMenu$getSubmenu()
        styleShortcuts <- playwith.getOption("styleShortcuts")
                                        #foo <- gtkMenuItem("Style shortcuts:")
                                        #foo["sensitive"] <- FALSE
                                        #styleMenu$append(foo)
        for (nm in names(styleShortcuts)) {
            item <- gtkMenuItem(nm)
            ssMenu$append(item)
            gSignalConnect(item, "activate", do.style_handler,
                           data = styleShortcuts[[nm]])
        }
    }
    ## themes
    thMenu <- manager$getWidget("/MenuBar/StyleMenu/ThemesMenu")
    if (!is.null(thMenu)) {
        thMenu <- thMenu$getSubmenu()
        themes <- playwith.getOption("themes")
                                        #foo <- gtkMenuItem("Themes:")
                                        #foo["sensitive"] <- FALSE
                                        #styleMenu$append(foo)
        for (nm in names(themes)) {
            item <- gtkMenuItem(nm)
            thMenu$append(item)
            gSignalConnect(item, "activate", do.style_handler,
                           data = themes[[nm]])
        }
    }
}

style.solid.points_handler <- function(widget, playState)
{
    if (widget["active"]) {
        pch <- 16
    } else {
        pch <- 1
    }
    playDevSet(playState)
    trellis.par.set(simpleTheme(pch = pch))
    if (playState$is.base)
        par(pch = pch)
    playReplot(playState)
}

style.trans.points_handler <- function(widget, playState)
{
    setAlpha <- function(col, alpha) {
        crgb <- col2rgb(col, alpha = TRUE)
        crgb[4] <- alpha * 255
        rgb(crgb[1], crgb[2], crgb[3], crgb[4], max = 255)
    }
    if (widget["active"]) {
#        alpha <- ginput("Translucency of points:",
#                       title = "Translucency of points", text = "0.25")
#        if ((length(name) == 0) || (nchar(name) == 0))
#            return()
        alpha <- guiTextInput("0.25", title = "Translucency of points",
                              prompt = "Translucency of points",
                              oneLiner = TRUE, width.chars = 7)
        if (is.null(alpha)) { ## cancelled
            widget["active"] <- FALSE
            return()
        }
        alpha <- as.numeric(alpha)
        if (is.na(alpha)) return()
    } else {
        alpha <- 1
    }
    playDevSet(playState)
    trellis.par.set(simpleTheme(alpha.points = alpha))
    if (playState$is.base) {
        col <- callArg(playState, "col")
        if (is.null(col)) col <- palette()[1]
        col <- setAlpha(col, alpha)
        #palette(c(col, palette()[-1]))
        callArg(playState, "col") <- col
    }
    playReplot(playState)
}

style.thick.lines_handler <- function(widget, playState)
{
    if (widget["active"]) {
        lwd <- 2
    } else {
        lwd <- 1
    }
    playDevSet(playState)
    trellis.par.set(list(plot.line = list(lwd = lwd),
                         superpose.line = list(lwd = lwd)))
    if (playState$is.base)
        par(lwd = lwd)
    playReplot(playState)
}

set.label.style_handler <- function(widget, playState)
{
    playFreezeGUI(playState)
    on.exit(playThawGUI(playState))
    ## constants
    faceList <- c("plain", "bold", "italic", "bold.italic")
    faceName <- function(x) {
        if (is.numeric(x)) x <- faceList[x]
        x
    }
    faceValue <- function(x) {
        ## return index of item in faceList
        match <- which(x == faceList)
        if (length(match)) return(match)
        x
    }
    colList <- palette()
    ## widgets
    wingroup <- ggroup(horizontal = FALSE)
    tmp1g <- ggroup(container = wingroup, spacing = 1)
    tmp2g <- ggroup(container = wingroup, spacing = 1)
    glabel(" Color:", container = tmp1g)
    wid.col <- gdroplist(colList, selected = 0, container = tmp1g,
                                  editable = TRUE)
    glabel(" Scale:", container = tmp1g)
    wid.cex <- gedit("", width = 4, container = tmp1g,
                     coerce.with = as.numeric)
    glabel(" Font:", container = tmp1g)
    wid.font <- gdroplist(c("", faceList), selected = 0, container = tmp1g,
                         editable = TRUE, coerce.with = faceValue)
    glabel(" Offset (chars):", container = tmp2g)
    wid.offset <- gedit("", width = 4, container = tmp2g,
                       coerce.with = as.numeric)
    glabel(" Line height factor:", container = tmp2g)
    wid.lineheight <- gedit("", width = 4, container = tmp2g,
                       coerce.with = as.numeric)
    ## current settings
    user.text <- trellis.par.get("user.text")
    if (is.null(eval(user.text)))
        user.text <- trellis.par.get("add.text")
    ## values
    svalue(wid.col) <- user.text$col
    svalue(wid.cex) <- toString(user.text$cex)
    svalue(wid.font) <- faceName(user.text$font)
    svalue(wid.offset) <- toString(playState$label.offset)
    svalue(wid.lineheight) <- toString(user.text$lineheight)
    ## handlers
    ok_handler <- function(h, ...)
    {
        ok <- function(x) if (is.na(x)) NULL else x
        playState$label.offset <- ok(svalue(wid.offset))
        newset <- list(col = svalue(wid.col),
                       cex = ok(svalue(wid.cex)),
                       font = ok(svalue(wid.font)),
                       lineheight = ok(svalue(wid.lineheight)))
        playDevSet(playState)
        trellis.par.set(user.text = newset)
        dispose(h$obj)
        playState$win$present()
        playReplot(playState)
    }
    gbasicdialog(title = "Label style", widget = wingroup,
                 handler = ok_handler)
}


set.arrow.style_handler <- function(widget, playState)
{
    playFreezeGUI(playState)
    on.exit(playThawGUI(playState))
    ## constants
    ltyList <- c("solid", "dashed", "dotted",
                 "dotdash", "longdash", "twodash", "blank")
    ltyName <- function(x) {
        if (identical(x, 0)) x <- "blank"
        if (is.numeric(x)) x <- ltyList[x]
        x
    }
    ltyValue <- function(x) {
        if (identical(x, "blank")) return(0)
        ## return index of item in ltyList
        match <- which(x == ltyList)
        if (length(match)) return(match)
        x
    }
    colList <- palette()
    ## widgets
    wingroup <- ggroup(horizontal = FALSE)
    tmp1g <- ggroup(container = wingroup, spacing = 1)
    tmp2g <- ggroup(container = wingroup, spacing = 1)
    glabel(" Color:", container = tmp1g)
    wid.col <- gdroplist(colList, selected = 0, container = tmp1g,
                         editable = TRUE)
    glabel(" Width:", container = tmp1g)
    wid.lwd <- gedit("", width = 4, container = tmp1g,
                     coerce.with = as.numeric)
    glabel(" Type:", container = tmp2g)
    wid.lty <- gdroplist(ltyList, selected = 0, container = tmp2g,
                          editable = TRUE, coerce.with = ltyValue)
    glabel(" Arrow head: Length:", container = tmp2g)
    wid.length <- gedit("", width = 4, container = tmp2g,
                        coerce.with = as.numeric)
    wid.unit <- gedit("", width = 5, container = tmp2g)
    wid.closed <- gcheckbox("Closed", container = tmp2g)
    glabel(" Angle:", container = tmp2g)
    wid.angle <- gedit("", width = 4, container = tmp2g,
                            coerce.with = as.numeric)
    ## current settings
    add.line <- trellis.par.get("add.line")
    arrow <- playState$arrow
    if (is.null(arrow$length)) arrow$length <- 0.25
    if (is.null(arrow$unit)) arrow$unit <- "inches"
    if (is.null(arrow$angle)) arrow$angle <- 30
    if (is.null(arrow$type)) arrow$type <- "open"
    ## values
    svalue(wid.col) <- add.line$col
    svalue(wid.lwd) <- toString(add.line$lwd)
    svalue(wid.lty) <- ltyName(add.line$lty)
    svalue(wid.length) <- toString(arrow$length)
    svalue(wid.unit) <- toString(arrow$unit)
    svalue(wid.closed) <- identical(arrow$type, "closed")
    svalue(wid.angle) <- toString(arrow$angle)
    ## handlers
    ok_handler <- function(h, ...)
    {
        ok <- function(x) if (is.na(x)) NULL else x
        arrow <- playState$arrow
        arrow$length <- svalue(wid.length)
        arrow$unit <- svalue(wid.unit)
        arrow$angle <- svalue(wid.angle)
        arrow$type <- if (svalue(wid.closed)) "closed"
        playState$arrow <- arrow
        playState$label.offset <- ok(svalue(wid.offset))
        newset <- list(col = svalue(wid.col),
                       lwd = ok(svalue(wid.lwd)),
                       lty = ok(svalue(wid.lty)))
        playDevSet(playState)
        trellis.par.set(add.line = newset)
        dispose(h$obj)
        playState$win$present()
        playReplot(playState)
    }
    gbasicdialog(title = "Arrow style", widget = wingroup,
                 handler = ok_handler)
}

set.brush.style_handler <- function(widget, playState)
{
    playFreezeGUI(playState)
    on.exit(playThawGUI(playState))
    ## constants
    pchList <-
        list(`open circle` = 1,
             `open square` = 0,
             `open diamond` = 5,
             `open triangle` = 2,
             `open tri.down` = 6,
             `solid circle` = 16,
             `solid square` = 15,
             `solid diamond` = 18,
             `solid triangle` = 17,
             `fill circle` = 21,
             `fill square` = 22,
             `fill diamond` = 23,
             `fill triangle` = 24,
             `fill tri.down` = 25,
             `plus (+)` = 3,
             `cross (x)` = 4,
             `star (*)` = 8,
             `dot (.)` = "."
             )
    pchName <- function(x) {
        match <- sapply(pchList, identical, x)
        if (any(match)) return(names(pchList)[match])
        x
    }
    pchValue <- function(x) {
        match <- which(names(pchList) == x)
        if (length(match)) return(pchList[[ match[1] ]])
        ## otherwise just return the value as character
        x
    }
    colList <- palette()
    ## widgets
    #dialog <- gwindow(title = "Brush style")
    wingroup <- ggroup(horizontal = FALSE)#, container = dialog)
    tmp1g <- ggroup(container = wingroup, spacing = 1)
    tmp2g <- ggroup(container = wingroup, spacing = 1)
    glabel(" Fill color:", container = tmp1g)
    wid.fill <- gdroplist(colList, selected = 0, container = tmp1g,
                                  editable = TRUE)
    glabel(" Symbol:", container = tmp1g)
    wid.pch <- gdroplist(names(pchList), selected = 0, container = tmp1g,
                         editable = TRUE, coerce.with = pchValue)
    glabel(" Outline:", container = tmp2g)
    wid.col <- gdroplist(colList, selected = 0, container = tmp2g,
                                  editable = TRUE)
    glabel(" Alpha:", container = tmp2g)
    wid.alpha <- gedit("", width = 4, container = tmp2g,
                       coerce.with = as.numeric)
    glabel(" Scale:", container = tmp2g)
    wid.cex <- gedit("", width = 4, container = tmp2g,
                     coerce.with = as.numeric)
    ## current settings
    brush.symbol <- trellis.par.get("brush.symbol")
    if (is.null(eval(brush.symbol)))
        brush.symbol <- brush.symbol.default
    ## values
    svalue(wid.fill) <- brush.symbol$fill
    svalue(wid.col) <- brush.symbol$col
    svalue(wid.alpha) <- toString(brush.symbol$alpha)
    svalue(wid.pch) <- pchName(brush.symbol$pch)
    svalue(wid.cex) <- toString(brush.symbol$cex)
    ## handlers
    ok_handler <- function(h, ...)
    {
        ok <- function(x) if (is.na(x)) NULL else x
        newbrush <- list(fill = svalue(wid.fill),
                         col = svalue(wid.col),
                         alpha = ok(svalue(wid.alpha)),
                         pch = ok(svalue(wid.pch)),
                         cex = ok(svalue(wid.cex)))
        playDevSet(playState)
        trellis.par.set(brush.symbol = newbrush)
        dispose(h$obj)
        playState$win$present()
        playReplot(playState)
    }
    gbasicdialog(title = "Brush style", widget = wingroup, # parent = ?
                 handler = ok_handler)
}
