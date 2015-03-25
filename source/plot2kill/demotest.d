/* These are demos/tests for Plot2Kill.  They serve both as tests
 * and as examples of usage.  Most testing is done here, mostly because
 * objective, automatically verifiable tests of correctness are hard to come
 * by for a plotting library, especially if avoiding testing implementation
 * details is also a goal.  It's much easier to just generate some plots
 * and see if they look right.
 *
 * Copyright (C) 2010-2012 David Simcha
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
version(test):
     
import std.conv, std.exception, std.algorithm, std.random,
    std.traits, std.math, std.array, std.range, std.mathspecial, std.stdio;

import plot2kill.all, plot2kill.util;


version(dfl) {
    enum string libName = "DFL";
} else {
    enum string libName = "GTK";
} 

void main(string[] args)
{
    // Test special-case handling of line graphs with perfectly vertical or
    // perfectly horizontal lines.
    Subplot(2, 2).addFigure(
        Figure(
            LineGraph([0.0, 3.0], [1.0, 1.0]),
            LineGraph([1.0, 1.0], [0.0, 2.0])
        ),
                            
        Figure(LineGraph([0.0, 3.0], [1.0, 1.0])),
        Figure(LineGraph([1.0, 1.0], [0.0, 2.0]))
    ).showAsMain();

    // Test dendrogram.
    {
        auto mat = [[3.0, 1, 4, 1, 5, 9, 2],
                    [8.0, 6, 7, 5, 3, 0, 9],
                    [2.0, 7, 1, 8, 2, 8, 1],
                    [7.0, 1, 2, 6, 9, 1, 3],
                    [4.0, 1, 8, 3, 0, 9, 3]];
        auto names = ["Pi", "80s Song", "e", "Made-up 1", "Made-up 2"];
        auto clusters = hierarchicalCluster(mat, ClusterBy.rows, names);
        auto dend = Dendrogram(clusters);
            
        dend.toLabeledFigure.showAsMain();
    }
    
    // Test linear fit line.
    {
        auto x = [8,6,7,5,4,0,9];
        auto y = [3,1,4,1,5,9,2];
        auto scatter = ScatterPlot(x, y);
        auto linear = LinearFit(x, y);
        
        Figure(scatter, linear)
            .xTickLabels([-0.5, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
            .showAsMain();
        
        // Test covariance fixes.
        auto plotArr = [scatter, scatter];
        auto fig2 = Figure(plotArr);
        fig2.removePlot(scatter, linear);
        fig2.addPlot(scatter, linear);
        
        auto arr2 = [scatter, scatter];
        fig2.removePlot(arr2);
        
        auto arr3 = [linear, linear];
        fig2.addPlot(arr3);
    }
    
    // Test hierarchical heat maps.
    {
        double[][] matrix = new double[][10];
        foreach(ref row; matrix) row = randArray!rNorm(10, 0, 1);
        auto rowLabels = to!(string[])(array(iota(10)));
        auto colLabels = to!(string[])(array(iota(10)));

        auto arr = [-2.5, -2, -1.5, -1, -0.5, 0, 0.5, 1, 1.5, 2];
        copy(arr, transversal(matrix, 1));
        copy(arr, transversal(matrix, 7));
        arr[] += randArray!rNorm(10, 0, 0.5)[];
        copy(arr, transversal(matrix, 3));

        hierarchicalHeatMap(matrix, rowLabels, colLabels)
            .colors([getColor(255, 0, 0), getColor(0, 0, 0), getColor(0, 255, 0)])
            .toFigure
            .xTickLabels(iota(1, 11), colLabels)
            .yTickLabels(iota(1, 11), rowLabels)
            .showAsMain();
    }
    
    // Test point symbols on line graphs.
    {
        LineGraph([8,6,7,5,3,0,9]).pointSymbol('O')
            .pointColor(getColor(255, 0, 0))
            .toFigure.saveToFile("foo.svg");
    }
    
    // Test stacked bar plots.
    auto stacked = Figure(
        stackedBar(iota(3), [[5, 3, 1], [1, 2, 3]], 0.6,
            ["Coffee", "Tea"]
        )
    ).legendLocation(LegendLocation.right)
        .title("Caffeine Consumption")
        .xLabel("Time of Day")
        .xTickLabels(iota(3), ["Morning", "Afternoon", "Evening"])
        .yLabel("Beverages");

    // Test removing a plot.
    auto fooHist = Histogram(randArray!rNorm(100, 0, 1), 10);
    stacked.addPlot(fooHist);

    stacked.removePlot(fooHist);
    stacked.showAsMain();

    // Test grouped bar plots.
    auto withoutCaffeine = [8, 6, 3];
    auto withCaffeine = [5, 3, 1];
    auto sleepinessPlot = groupedBar(
        iota(3), [withoutCaffeine, withCaffeine], 0.6,
        ["W/o Caffeine", "W/ Caffeine"],
        [getColor(96, 96, 255), getColor(255, 96, 96)]
    );
    auto sleepinessFig = Figure(sleepinessPlot)
        .title("Sleepiness Survey")
        .yLabel("Sleepiness Rating")
        .xLabel("Activity")
        .legendLocation(LegendLocation.right)
        .gridIntensity(cast(ubyte) 100)
        .horizontalGrid(true)
        .xTickLabels(
            iota(3),
            ["In Meeting", "On Phone", "Coding"]
        );
    sleepinessFig.showAsMain();

    // Test box-and whisker plots.
    auto boxFigNorm = BoxPlot(0.05).addData(
        randArray!rNorm(100, 0, 1),
        randArray!rNorm(100, 0, 0.5),
        randArray!rNorm(100, 1, 2)
    ).legendText("Normal");

    auto boxFigNonNorm = BoxPlot(0.05)
        .offset(boxFigNorm.nBoxes)
        .addData(
            randArray!rExponential(100, 0.5),
            randArray!uniform(100, -2.0, 2.0) )
        .color(getColor(255, 0, 0))
        .legendText("Non-Normal");

    auto boxFig = Figure(boxFigNorm, boxFigNonNorm)
        .rotatedXTick(true)
        .legendLocation(LegendLocation.right)
        .xTickLabels(iota(5), [
            "Normal(0, 1)", "Normal(0, 0.5)", "Normal(1, 2)",
            "Exponential(0.5)", "Uniform(-2, 2)"]
        );

    boxFig.showAsMain();

    // Test line graphs and histograms on the same plot.
    auto histRand = Histogram(
        randArray!rNorm(5_000, 0, 1), 100, -5, 5, OutOfBounds.ignore);
    histRand.put(
        Histogram(randArray!rNorm(5_000, 0, 1), 100, -5, 5, OutOfBounds.ignore)
    );
    histRand.legendText = "Empirical";

    auto histLine = ContinuousFunction(&stdNormal, -5, 5);
    
    histLine.legendText = "Theoretical";
    histRand.scaleDistributionFunction(histLine);
    histLine.lineColor = getColor(255, 0, 0);
    histLine.lineWidth = 3;

    auto hist = Figure(histRand, histLine);
    hist.addLines(
        FigureLine(-2, 0, -2, hist.topMost, getColor(128, 0, 0), 2),
        FigureLine(2, 0, 2, hist.topMost, getColor(128, 0, 0), 2)
    );

    hist.title = "Normal Distrib.";
    hist.xLabel = "Random Variable";
    hist.yLabel = "Count";
    hist.saveToFile("foo" ~ libName ~ ".png");
    hist.saveToFile("foo" ~ libName ~ ".bmp");
    
    hist.showAsMain();

    // Test error bars.
    auto errs = [0.1, 0.2, 0.3, 0.4];
    auto linesWithErrors =
        LineGraph([1,2,3,4], [1,2,3,8], errs, errs);
    linesWithErrors.lineColor = getColor(255, 0, 0);
    auto linesWithErrorsFig = linesWithErrors.toFigure;
    linesWithErrorsFig.title = "Error Bars";
    linesWithErrorsFig.showAsMain();

    // Plot a normal approximation of the binomial distribution superimposed
    // on the exact distribution.
    auto binomExact =
        DiscreteFunction((int x) { return binomialPMF(x, 8, 0.5); }, 0, 8);
    binomExact.legendText = "Exact";
    auto binomApprox = ContinuousFunction(
        (double x) { return stdNormal((x - 4) / SQRT2) / SQRT2; }, -1, 9, 100
    );
        
    binomApprox.legendText = "Approx.";
    binomApprox.lineWidth = 2;
    auto binom = Figure(binomExact, binomApprox);
    binom.title = "Binomial";
    binom.xLabel = "N Successes";
    binom.yLabel = "Probability";
    binom.xTickLabels(array(iota(0, 9, 1)));
    binom.legendLocation = LegendLocation.top;
    binom.xLim(0, 8);
    binom.showAsMain();

    // Test a basic scatter plot with grid lines.
    auto scatter = ScatterPlot(
        randArray!rNorm(100, 0, 1),
        randArray!rNorm(100, 0, 1)
    ).legendText("Point").pointSize(10).pointColor(getColor(255, 0, 255)).toFigure;
    scatter.xLim(-2, 2);
    scatter.yLim(-2, 2);
    scatter.verticalGrid = true;
    scatter.horizontalGrid = true;
    scatter.showAsMain();

    // Test error bars with bar plots.
    auto bars = BarPlot([1,2,3], [8,7,3], 0.5, [1,2,4], [1,2,4]);
    auto barFig = bars.toFigure;
    barFig.xTickLabels(bars.centers, ["Plan A", "Plan B", "Plan C"]);
    barFig.title = "Useless Plans";
    barFig.yLabel = "Screwedness";
    barFig.rotatedXTick = true;
    barFig.showAsMain();

    // Test QQ plots.
    auto qq = QQPlot(
        randArray!rNorm(100, 0, 1),
        &normalDistributionInverse
    ).toFigure;
    qq.title = "Normal(0, 1) Theoretical vs. Actual";
    qq.xLabel = "Theoretical Quantile";
    qq.yLabel = "Actual Quantile";
    qq.showAsMain();

    // Test equal frequency histograms.
    auto frqHist = FrequencyHistogram(
        randArray!rNorm(100_000, 0, 1), 100).toFigure;
    frqHist.xLim(-2.5, 2.5);

    // Test unique histograms.
    auto uniqueHist = UniqueHistogram(
        randArray!uniform(10_000, 0, 8)
    );
    uniqueHist.histType = HistType.Probability;
    uniqueHist.barColor = getColor(0, 200, 0);
    auto uniqueHistFig = uniqueHist.toLabeledFigure;
    uniqueHistFig.title = "Unique Histogram";
    uniqueHistFig.showAsMain();

    // Test heat scatter plots.
    auto heatScatter = HeatScatter(100, 100, -6, 6, -5, 5);
    heatScatter.boundsBehavior = OutOfBounds.Ignore;
    heatScatter.colors = [getColor(0, 128, 0),
        getColor(255, 255, 0), getColor(255, 0, 0), getColor(255, 255, 255)];
    foreach(i; 0..500_000) {
        auto num1 = rNorm(-2, 1);
        auto num2 = rNorm(1, 1);
        num1 += num2;
        heatScatter.put(num1, num2);
    }
    auto a1 = randArray!rNorm(500_000, -2, 1);
    auto a2 = randArray!rNorm(500_000,  1, 1);
    a1[] += a2[];
    heatScatter.put(
        HeatScatter(a1, a2, 100, 100, -6, 6, -5, 5, OutOfBounds.Ignore)
    );

    auto heatScatterFig = heatScatter.toFigure
        .xLim(-4, 2)
        .yLim(-2, 4)
        .title("2D Histogram")
        .xLabel("Normal(-2, 1) + Y[i]")
        .yLabel("Normal(1, 1)");

   //heatScatterFig.saveToFile("bar" ~ libName ~ ".png", ".png", 640, 480);

   heatScatterFig.showAsMain();

    // Test subplots.  Put a whole bunch of what we did on one big subplot.
    enum string titleStuff = "Plot2Kill " ~ libName ~
        " Demo  (Programmatically  saved, no longer a screenshot)";
    enum string subplotY = "Pretty Rotated Text";


    auto sp = Subplot().addFigure
        (hist, binom, barFig, linesWithErrorsFig, scatter,
         qq, frqHist, uniqueHistFig, heatScatterFig, boxFig, sleepinessFig,
         stacked)
        .title(titleStuff)
        .yLabel(subplotY)
        .xLabel("Boring X-Axis Label");

    // Test saving results to a file.
    version(dfl) {
    } else {
        sp.saveToFile("sp.pdf", 1280, 1024);
        sp.saveToFile("sp.svg", 1280, 1024);
    }

    sp.saveToFile("sp" ~ libName ~ ".bmp", 1280, 1024);
    sp.saveToFile("sp" ~ libName ~ ".png", 1280, 1024);
    
    // Test covariance fixes.
    auto sp2 = Subplot();
    auto figArr = [hist, binom];
    sp2.addFigure(figArr);

    sp.showAsMain();

}

// Statistical functions for statistics oriented plots.  These are mostly
// cut and pasted from my dstats library.
double[] randArray(alias randFun, Args...)(size_t N, auto ref Args args) {
    auto ret = uninitializedArray!(double[])(N);
    foreach(ref elem; ret) {
        elem = randFun(args);
    }

    return ret;
}

double rNorm(double mean, double sd) {
    immutable p = uniform(0.0, 1.0);
    return normalDistributionInverse(p) * sd + mean;
}

double rExponential(double lambda) {
    double p = uniform(0.0, 1.0);
    return -log(p) / lambda;
}

double stdNormal(double x) {
    return exp(-(x * x) / 2) / sqrt(2 * PI);
}

double binomialPMF(ulong k, ulong n, double p) {
    return exp(logNcomb(n, k) + k * log(p) + (n - k) * log(1 - p));
}

double logNcomb(ulong n, ulong k) {
    return logGamma(n + 1) - (logGamma(k + 1) + logGamma(n - k + 1));
}