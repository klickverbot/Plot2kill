/**This module contains the Subplot object.  This allows placing multiple
 * plots on a single form in a simple grid arrangement..
 *
 * Copyright (C) 2010-2011 David Simcha
 *
 * License:
 *
 * Boost Software License - Version 1.0 - August 17th, 2003
 *
 * Permission is hereby granted, free of charge, to any person or organization
 * obtaining a copy of the software and accompanying documentation covered by
 * this license (the "Software") to use, reproduce, display, distribute,
 * execute, and transmit the Software, and to prepare derivative works of the
 * Software, and to permit third-parties to whom the Software is furnished to
 * do so, all subject to the following:
 *
 * The copyright notices in the Software and this entire statement, including
 * the above license grant, this restriction and the following disclaimer,
 * must be included in all copies of the Software, in whole or in part, and
 * all derivative works of the Software, unless such copies or derivative
 * works are solely in the form of machine-executable object code generated by
 * a source language processor.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
 * SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
 * FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
 * ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */
module plot2kill.subplot;

import plot2kill.figure;
import plot2kill.util;

/**This is the GUI-agnostic base class for a Subplot.  See the Subplot
 * class, which derives from this class and has a few GUI-specific things added.
 *
 * Subplot objects allows for one or more subplots to be created in a single
 * window or a single file.  Each subplot is represented by a FigureBase.
 * In the default plot window, double-clicking on any subplot zooms
 * in on it.  Double-clicking again zooms out.
 *
 * Examples:
 * ---
 * auto histFig = Histogram(someNumbers, 10).toFigure;
 * auto scatterFig = ScatterPlot(someNumbers, someMoreNumbers).toFigure;
 * auto sub = SubPlot(1, 2);  // 1 row, 2 columns.
 * sub.addPlot(histFig, 0, 0);  // Add the histogram in the 0th row, 0th column.
 * sub.addPlot(scatterFig, 0, 1);  // Ditto.
 * sub.showAsMain();
 * ---
 */
abstract class SubplotBase : FigureBase {
private:
    uint nRows;
    uint nColumns;

    double topMargin = 0;
    double bottomMargin = 0;
    double leftMargin = 0;
    enum int rightMargin = 10;  // No label here so it can be an enum.

    FigureBase[][] figs;
    FigureBase _zoomedFigure;

    invariant() {
        assert(figs.length == nRows);
        foreach(row; figs) {
            assert(row.length == nColumns);
        }
    }

    void nullFontsToDefaults() {
        if(nullOrInit(_titleFont)) {
            _titleFont = getFont(plot2kill.util.defaultFont, 18 + fontSizeAdjust);
            assert(!nullOrInit(_titleFont));
        }

        if(nullOrInit(_xLabelFont)) {
            _xLabelFont = getFont(plot2kill.util.defaultFont, 14 + fontSizeAdjust);
            assert(!nullOrInit(_xLabelFont));
        }

        if(nullOrInit(_yLabelFont)) {
            _yLabelFont = getFont(plot2kill.util.defaultFont, 14 + fontSizeAdjust);
            assert(!nullOrInit(_yLabelFont));
        }
    }

    void drawLabels() {
        // The amount of margin that's left before the labels are even drawn.
        enum labelMargin = 10;
        nullFontsToDefaults();
        if(_xLabel.length > 0) {
            immutable textSize = measureText(_xLabel, _xLabelFont);
            bottomMargin = textSize.height + labelMargin;
            drawText(
                _xLabel, _xLabelFont, getColor(0, 0, 0),
                PlotRect(0,
                    this.height - bottomMargin,
                    this.width, textSize.height),
                TextAlignment.Center
            );
        } else {
            bottomMargin = 0;
        }

        if(_title.length > 0) {
            immutable textSize = measureText(_title, _titleFont);
            topMargin = textSize.height + labelMargin;
            drawText(
                _title, _titleFont, getColor(0, 0, 0),
                PlotRect(0, labelMargin, width, topMargin - labelMargin),
                TextAlignment.Center
            );
        } else {
            topMargin = 0;
        }

        if(_yLabel.length > 0) {
            immutable textSize = measureText(_yLabel, _yLabelFont);
            leftMargin = textSize.height + labelMargin;


            drawRotatedText(
                _yLabel, _yLabelFont, getColor(0, 0, 0),
                PlotRect(labelMargin, 0, textSize.height, this.height),
                TextAlignment.Center
            );
        }
    }

    // Gets the figure width assuming this has a width of width.
    // The explicit parameter is necessary because this can be called
    // at times other than during drawing.
    double getFigWidth(double width) {
        return (width - rightMargin - leftMargin) / nColumns;
    }

    // Ditto.
    double getFigHeight(double height) {
        return (height - topMargin - bottomMargin) / nRows;
    }


    void drawFigureZoomedOut() {
        assert(context !is null);

        fillRectangle(getBrush(getColor(255, 255, 255)), 0, 0, width, height);
        drawLabels();

        immutable figWidth = getFigWidth(this.width);
        immutable figHeight = getFigHeight(this.height);

        foreach(rowIndex, row; figs) {
            foreach(colIndex, fig; row) {
                if(fig is null) {
                    continue;
                }

                immutable xPos = colIndex * figWidth + leftMargin + xOffset;
                immutable yPos = rowIndex * figHeight + topMargin + yOffset;
                auto whereToDraw = PlotRect(xPos, yPos, figWidth, figHeight);
                fig.drawTo(context, whereToDraw);
            }
        }

        // Temporary kludge:  Draw labels a second time to prevent them
        // from being cut off by plots.  Linux's text measuring sucks.
        drawLabels();
    }

    void drawFigureZoomedIn() {
        assert(context !is null);
        assert(zoomedFigure !is null);

        zoomedFigure.drawTo
            (context, PlotRect(xOffset, yOffset, width, height));
    }

    // This code is really, REALLY inefficient, but I don't care because it's
    // safe to say N will always be tiny, and it's simple and readable.
    void doAdd(FigureBase fig) {
        // Search for empty slots;
        foreach(row; figs) foreach(ref cell; row) {
            if(cell is null) {
                cell = fig;
                return;
            }
        }

        // Add a new row.
        if(nColumns > nRows) {
            nRows++;
            figs ~= new FigureBase[nColumns];
            figs[$ - 1][0] = fig;
            return;
        }

        // Add a new column.
        nColumns++;
        auto oldFigs = figs;
        figs = new FigureBase[][](nRows, nColumns);

        foreach(row; oldFigs) foreach(cell; row) {
            doAdd(cell);
        }

        doAdd(fig);
    }

protected:

    this() {}

    this(uint nRows, uint nColumns) {
        enforce(nRows >= 1 && nColumns >= 1,
            "Subplot figures must have at least 1 cell.  Can't create a " ~
            " subplot of dimensions " ~ to!string(nRows) ~ "x" ~
            to!string(nColumns) ~ "."
        );

        this.nRows = nRows;
        this.nColumns = nColumns;

        figs = new FigureBase[][](nRows, nColumns);
    }

    override void drawImpl() {
        assert(context);

        if(zoomedFigure is null) {
            drawFigureZoomedOut();
        } else {
            drawFigureZoomedIn();
        }
    }

public:

    /**Create an instance with nRows rows and nColumns columns.*/
    static Subplot opCall(uint nRows, uint nColumns) {
        return new Subplot(nRows, nColumns);
    }

    /**Create an empty Subplot instance.*/
    static Subplot opCall() {
        return new Subplot();
    }

    override int defaultWindowWidth() {
        return 1024;
    }

    override int defaultWindowHeight() {
        return 768;
    }

    override int minWindowWidth() {
        return 800;
    }

    override int minWindowHeight() {
        return 600;
    }

    /**Add a figure to the subplot in the given row and column.
     */
    This addFigure(this This)(FigureBase fig, uint row, uint col) {
        enforce(row < nRows && col < nColumns, std.conv.text(
            "Can't add a plot to cell (",row, ", ", col, ") of a ", nRows,
            "x", nColumns, " Subplot."));

        figs[row][col] = fig;
        return cast(This) this;
    }

    /**Add a figure to the subplot using the default layout, which is as
     * follows:
     *
     * 1.  Slots will be searched left-to-right, top-to-bottom, rows first.
     *     If an empty one is found, the figure will be added there.
     *
     * 2.  If no empty slots are found and nColumns <= nRows, then another
     *     column will be added. The N existing figures will be moved such that
     *     they are the first N figures in left-to-right, top-to-bottom,
     *     rows first order and their ordering according to this predicate
     *     does not change.  The figure to be added will be the last figure
     *     according to this predicate.
     *
     * 3.  If no empty slots are found and nColumns > nRows, a new row will
     *     be created and the figure will be stored as the first element in
     *     that row.
     *
     * Notes: If you add figures with the overload that allows explicit row and
     *        column specification, and then call this overload, the coordinates
     *        of previously added figures may be changed.
     *
     *        If you pass multiple figures, they are simply added iteratively
     *        according to these rules.
     */
     This addFigure(this This)(FigureBase[] toAdd) {
         foreach(fig; toAdd) {
             doAdd(fig);
         }

         return cast(This) this;
     }
     
     /// Ditto
     This addFigure(this This, F...)(F toAdd)
     if(allSatisfy!(isFigureBase, toAdd)) {
        FigureBase[toAdd.length] arr;
        foreach(i, elem; toAdd) arr[i] = elem;
        return addFigure(arr[]);
     }

     /**
     Returns the zoomed figure, or null if no figure is currently zoomed.
     */
     FigureBase zoomedFigure() {
         return _zoomedFigure;
     }
};

version(dfl) {

import dfl.form, dfl.label, dfl.control, dfl.event, dfl.picturebox, dfl.base,
    dfl.application;

///
class Subplot : SubplotBase {

    private this(uint nRows, uint nColumns) {
        super(nRows, nColumns);
    }

    private this() {
        super();
    }

    ///
    override FigureControl toControl() {
        return new SubplotControl(this);
    }

    ///
    override void showAsMain() {
        Application.run(new DefaultPlotWindow(this.toControl));
    }
}

/* This class is an implementation detail.  All public code should use it as
 * its base class.  It's very tightly coupled to the Subplot class because
 * it contains behavior that doesn't make any sense to expose in a more
 * transparent way.
 */
package class SubplotControl : FigureControl {

    this(Subplot sp) {
        super(sp);
       // this.doubleClick ~= &zoomEvent;
        this.size = Size(1024, 768);
        this.mouseDown ~= &zoomEvent;
    }

    /* Returns the FigureBase, downcast to a Subplot.  This is safe because our
     * C'tor only accepts Subplots.
     */
    Subplot subplot() {
        auto ret = cast(Subplot) figure;

        // Safeguard in case this gets refactored and our assumptions break:
        assert(ret);
        return ret;
    }

    FigureBase getFigureAt(double x, double y, Subplot sp) {
        with(sp) {
            if(x < leftMargin || y < topMargin) {
                return null;
            }

            immutable figWidth = getFigWidth(this.width);
            immutable figHeight = getFigHeight(this.height);


            immutable xCoord = to!int((x - leftMargin) / figWidth);
            immutable yCoord = to!int((y - topMargin) / figHeight);
            if(xCoord < nColumns && yCoord < nRows) {
                return figs[yCoord][xCoord];
            } else {
                return null;
            }
        }
    }

    // Handles zooming in on double click.
    void zoomEvent(Control c, MouseEventArgs ea) {
        auto sp = subplot();

        if(ea.button != MouseButtons.LEFT || ea.clicks != 2) {
            return;
        }

        with(sp) {
            if(_zoomedFigure is null) {
                auto toZoom = getFigureAt(ea.x, ea.y, subplot());
                if(toZoom !is null) {
                    _zoomedFigure = toZoom;
                    draw();
                }
            } else if(cast(Subplot) _zoomedFigure) {
                // Support multilevel zoom.
                auto toZoom = getFigureAt(ea.x, ea.y,
                    cast(Subplot) _zoomedFigure);

                // If toZoom is null, that's fine.  Just zoom out.
                _zoomedFigure = toZoom;
                draw();
            } else {
                _zoomedFigure = null;
                draw();
            }
        }
    }
}

}

version(gtk) {

import gtk.DrawingArea, gdk.Drawable, gtk.Widget;

///
class Subplot : SubplotBase {

    private this(uint nRows, uint nColumns) {
        super(nRows, nColumns);
    }

    private this() {
        super();
    }

    ///
    override FigureWidget toWidget() {
        defaultInit();
        return new SubplotWidget(this);
    }
}

/* This class is an implementation detail.  All public code should use it as
 * its base class.  It's very tightly coupled to the Subplot class because
 * it contains bejavior that doesn't make any sense to expose in a more
 * transparent way.
 */
package class SubplotWidget : FigureWidget {

    this(Subplot sp) {
        super(sp);
        this.addOnButtonPress(&zoomEvent);
        //this.addOnExpose(&onDrawingExpose);
        this.setSizeRequest(800, 600);
    }

    /* Returns the FigureBase, downcast to a Subplot.  This is safe because our
     * C'tor only accepts Subplots.
     */
    Subplot subplot() {
        auto ret = cast(Subplot) figure;

        // Safeguard in case this gets refactored and our assumptions break:
        assert(ret);
        return ret;
    }

//    bool onDrawingExpose(GdkEventExpose* event, Widget drawingArea) {
//        draw();
//        return true;
//    }

    FigureBase getFigureAt(double x, double y, Subplot sp) {
        with(sp) {
            if(x < leftMargin || y < topMargin) {
                return null;
            }

            immutable figWidth = getFigWidth(this.getWidth);
            immutable figHeight = getFigHeight(this.getHeight);


            immutable xCoord = to!int((x - leftMargin) / figWidth);
            immutable yCoord = to!int((y - topMargin) / figHeight);
            if(xCoord < nColumns && yCoord < nRows) {
                return figs[yCoord][xCoord];
            } else {
                return null;
            }
        }
    }

    // Handles zooming in on double click.
    bool zoomEvent(GdkEventButton* press, Widget widget) {
        auto sp = subplot();

        with(sp) {
            if(press.type != GdkEventType.DOUBLE_BUTTON_PRESS
               || press.button != 1) {
                return false;
            }

            if(_zoomedFigure is null) {
                auto toZoom = getFigureAt(press.x, press.y, sp);
                if(toZoom !is null) {
                    _zoomedFigure = toZoom;
                    draw();
                }
            } else if(cast(Subplot) _zoomedFigure) {
                // Support multilevel zoom.
                auto toZoom = getFigureAt(press.x, press.y,
                    cast(Subplot) _zoomedFigure);

                // If toZoom is null, that's fine.  Just zoom out.
                _zoomedFigure = toZoom;
                draw();
            } else {
                _zoomedFigure = null;
                draw();
            }

            return true;
        }
    }
}
}

private template isFigureBase(F) {
    enum isFigureBase = is(F : FigureBase);
}
