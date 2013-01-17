###############################################################################
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
###############################################################################
# Create Technical Analysis Plots
# plota = plot + ta
# Copyright (C) 2011  Michael Kapler
#
# For more information please visit my blog at www.SystematicInvestor.wordpress.com
# or drop me a line at TheSystematicInvestor at gmail
###############################################################################


###############################################################################
# Global Plota Control Parameters & Themes
###############################################################################
plota.theme <- function
(
	col.border = 'black',
	col.up = 'green',
	col.dn = 'red',
	col.x.highlight = 'orange',
	col.y.highlight = 'orange',
	alpha=NA
) 
{
	col = c(col.border, col.up, col.dn, col.x.highlight, col.y.highlight)
	if(!is.na(alpha)) col = col.add.alpha(col, alpha)
	
	plota.control$col.border = col[1]
	plota.control$col.up = col[2]
	plota.control$col.dn = col[3]
	plota.control$col.x.highlight = col[4]
	plota.control$col.y.highlight = col[5]
}

plota.theme.blue.red <- function(alpha=NA) 
{
	plota.theme(
		col.border = 'black',
		col.up = 'blue',
		col.dn = 'red',
		alpha = alpha
		)
}

plota.theme.green.orange <- function(alpha=NA) 
{
	plota.theme(
		col.border = rgb(68,68,68, maxColorValue=255),
		col.up = rgb(0,204,0, maxColorValue=255),
		col.dn = rgb(255,119,0, maxColorValue=255),
		alpha = alpha
		)		
}

plota.theme.gray.orange <- function(alpha=NA) 
{
	plota.theme(
		col.border = '#444444',
		col.up = '#BEBEBE',
		col.dn = '#FF7700',
		alpha = alpha
		)				
}

plota.control = new.env()
	plota.control$col.border = 'black'
	plota.control$col.up = 'green'
	plota.control$col.dn = 'red'
	plota.control$col.x.highlight = 'orange'
	plota.control$col.y.highlight = 'orange'
	plota.control$xaxis.ticks = c()

# set default theme	
plota.theme.green.orange();

###############################################################################
# Work with colors
###############################################################################
# make color semi-transparent
col.add.alpha <- function
(
	col, 		# color(s)
	alpha=150	# alpha
) 
{
	rgb(t(col2rgb(col)), alpha=alpha, maxColorValue = 255)	
}

###############################################################################
# plota - plot for time series
###############################################################################
plota <- function
(
	y,					# xts object to plot
	main = NULL,		# plot title
	plotX = TRUE,		# flag to display X axis
	LeftMargin = 0,		# to plot second Y axis, set LeftMargin=3
	x.highlight = NULL,	# segments to highlight along X axis
	y.highlight = NULL,	# segments to highlight along Y axis
	las = 1,			# rotation of Y axis labels
	type = 'n',			# plot type
	xlab = '',			# X label
	ylab = '',			# Y label
	ylim = NULL,		# range on Y values
	log = '',			# log scale x, y, xy axes
	...					# other parameters to plot
)
{
	# set plot margins : bottom,left,top,right
	hasTitle = !is.null(main);
	par( mar = c(iif(plotX,2,0), LeftMargin , iif(hasTitle,2,0), 3) )
	
	# set plot y range
	if(has.Cl(y)) y1 = Cl(y) else y1 = y[,1]
	if( is.null(ylim) ) {
		ylim = range(y1, na.rm = T)
		switch(type,
			'ohlc' = ,
			'hl' = ,
			'candle' = { ylim = range(OHLC(y), na.rm = T) },
			'volume' = { y1 = Vo(y); ylim = range(Vo(y), na.rm = T) }
		)
	}
		
	# create plot frame, do not plot data
	temp.x = attr(y, 'index')	
	plot( temp.x, y1, xlab = xlab, ylab = ylab, main = main,
		type = 'n', yaxt = 'n', xaxt = 'n', ylim = ylim, log = log, ... )
		
		# Y axis rotation in 90 degrees increments : las=0,las=1,las=2,las=3
		axis(4, las = las)
		
		# plot X axis
		class(temp.x) = c('POSIXct', 'POSIXt')	
		plota.control$xaxis.ticks = axis.POSIXct(1, temp.x,labels = plotX, tick = plotX)
		
				
	# highlight logic
	if( !is.null(x.highlight) ) plota.x.highlight(y, x.highlight); 	
	if( !is.null(y.highlight) ) plota.y.highlight(y, y.highlight); 	
		
	# plot grid
	plota.grid()
	
	# plot data
	switch(type,
		'candle' = plota.candle(y, ...),
		'hl' = plota.hl(y, ...),
		'ohlc' = plota.ohlc(y, ...),
		'volume' = plota.volume(y, ...),
		{  lines(temp.x, y1, type=type, ...) }
	)
	
	# plot box
	box();
}

###############################################################################
# plota2Y - add second Y axis to existing plot
###############################################################################
plota2Y <- function(
	y,			# xts object to plot
	las = 1,	# rotation of Y axis labels
	type = 'n',	# plot type
	...			# other parameters to plot
)
{
	# exctract visible plot data
	xlim = par('usr')[1:2]

	# subset	
	class(xlim) = c('POSIXct', 'POSIXt')
	y1 = y[paste(format(xlim, '%Y:%m:%d %H:%M:%S'), sep = '', collapse = '::')]	
	

	# plot
	par(new = TRUE)
	xlim = par('usr')[1:2]
	plot( attr(y1, 'index') , y1[,1], xlim = xlim, xaxs = 'i', type = type,
		yaxt = 'n', xaxt = 'n', xlab = '', ylab = '', axes = F, ... )
		
		# Y axis rotation
		axis(2, las = las, ...) 
}

###############################################################################
# plota.grid - plot grid
###############################################################################
plota.grid <- function() 
{
	abline( h = axTicks(2), col = 'lightgray', lty = 'dotted')
	abline( v = plota.control$xaxis.ticks, col = 'lightgray', lty = 'dotted')
}

###############################################################################
# plota.lines - plot lines
###############################################################################
plota.lines <- function(
	y,					# xts object to plot
	type = 'l',			# plot type
	col = par('col'),	# color
	...					# other parameters to lines
)
{
	if(has.Cl(y)) y1 = Cl(y) else y1 = y[,1]	
	
	temp.x = attr(y, 'index')
	
	if( type == 'l' & len(col) > 1 ) {
		for( icol in unique(col) ) {
			lines(temp.x, iif(col == icol, y1, NA), type = type, col = icol, ...)
		}
	} else {
		lines(temp.x, y1, type = type, col = col, ...)
	}
}
	
###############################################################################
# plota.format - format numbers using 1000 separator
###############################################################################
plota.format <- function(
	temp,			# numbers
	nround = 2,		# number of rounding digits
	sprefix = '',	# start prefix string
	eprefix = ''	# end postfix string
)
{
	return( paste(sprefix, 
			format(round(as.numeric(temp), nround), big.mark = ',', scientific=FALSE),
			eprefix ,sep='') )
}

###############################################################################
# plota.legend - plot legend
###############################################################################
plota.legend <- function
(
	labels,					# labels
	fill = NULL,			# fill colors
	lastobs = NULL, 		# last observations
	x = 'topleft',			# location of legend
	merge = F, 				# merge
	bty = 'n',				# box
	yformat = plota.format,	# format values
	...						# other parameters to legend
)
{
	# split fill colors & labels
	if( !is.null(fill) ) fill = spl( as.character(fill) )	
	labels = spl( as.character(labels) )
	
	# if last observations, add them to labels
	if( !is.null(lastobs) ) {
		if( is.list(lastobs) ) {
			labels1 = sapply(lastobs, function(x) unclass(last(x))[1])
		} else { 
			labels1 = unclass(last(lastobs))[1]; 
		}		
		# format last observations
		labels = paste(labels, match.fun(yformat)( labels1 ))		
	}	
	
	# plot legend
	legend(x, legend = labels, fill = fill, merge = merge, bty = bty, ...)
}	

###############################################################################
# plota.layout - create layout
###############################################################################
plota.layout <- function(
	ilayout,	# matrix stored as a string 
	delim = ','	# delimiter
)
{	
	ilayout = matrix( as.double(spl( gsub('\n', delim, ilayout), delim)), 
				nrow = len(spl(ilayout, '\n')), byrow=TRUE)
	layout(mat = ilayout)
}	

###############################################################################
# plota.dx - determine data spacing along X axis
###############################################################################
plota.dx <- function
(
	y	# xts object to plot
)
{ 
	# determine portion of data visible on X axis
	xlim = par('usr')[1:2]

	# subset	
	class(xlim) = c('POSIXct', 'POSIXt')
	y1 = y[paste(format(xlim, '%Y:%m:%d %H:%M:%S'), sep = '', collapse = '::')]

	
	# R by default extends xrange by 1.08
	xlim = par('usr')[1:2]
	xportion = min(1, diff(unclass(range(attr(y1, 'index'))))*1.08 / diff(xlim) )
	return( xportion * diff(xlim) / ( 2* nrow(y1)  ) )
}

###############################################################################
# plota.x.highlight - highlight vertical segments
###############################################################################
plota.x.highlight <- function
(
	y,						# xts object to plot
	highlight,				# segments to highlight along X axis
	col = plota.control$col.x.highlight
)
{
	if(len(col)==1) {
		plota.x.highlight.helper(y, highlight, col = col)		
	} else { # do for each color
		for( icol in unique(col[highlight]) ) {
			plota.x.highlight.helper(y, iif(col == icol, highlight, FALSE), col = icol)					
		}
	}
}


plota.x.highlight.helper <- function
(
	y,						# xts object to plot
	highlight,				# segments to highlight along X axis
	col = plota.control$col.x.highlight
)
{
	dx = plota.dx(y);	
	hl_index = highlight;
	
	if( is.logical(highlight) ) hl_index = which(highlight);
	if( identical(unique(highlight) , c(0, 1)) ) hl_index = which(as.logical(highlight));

	# determine continuous segments to highlight
	hl_index1 = which(diff(hl_index) > 1 )	
	hl_index = hl_index[ sort(c(1, len(hl_index), hl_index1, (hl_index1+1))) ]
	
	# see par documentation
	temp.y = par('usr')[3:4]
	if(par('ylog')) temp.y = 10^temp.y
	
	
	temp.x = attr(y, 'index')		
	for( i in seq(1,len(hl_index),2) ) {		
		rect(temp.x[hl_index[i]] - dx/2, temp.y[1],
			temp.x[hl_index[(i + 1)]] + dx/2, temp.y[2],
            col = col, border = col ) 		
	}
	box();		
}

###############################################################################
# plota.y.highlight - highlight horizontal segments
###############################################################################
plota.y.highlight <- function
(
	y,					# xts object to plot
	highlight,			# segments to highlight along Y axis
	col = plota.control$col.y.highlight
)
{
	# see par documentation
	temp.y = par('usr')[3:4]
	if(par('ylog')) temp.y = 10^temp.y

	temp.x = par('usr')[1:2]
	if(par('xlog')) temp.x = 10^temp.x
		
	highlight[highlight == Inf] = temp.y[2]
	highlight[highlight == -Inf] = temp.y[1]
	
	for( i in seq(1,len(highlight),by=2) ) {
		rect(temp.x[1], highlight[i],
			temp.x[2], highlight[(i + 1)],
            col = col, border = col ) 			
	}
	box();
}

###############################################################################
# plota color helper functions for candles and volume
###############################################################################
plota.candle.col <- function(	y ) { 
	return( iif( Cl(y)>Op(y), plota.control$col.up, plota.control$col.dn) )
}
plota.volume.col <- function( y ) { 
	return( iif( Cl(y)>mlag(Cl(y)), plota.control$col.up, plota.control$col.dn) )
}

###############################################################################
# plota.candle - plot candles
#  plota.candle will try to plot candles if dx is sufficient
#  otherwise ohlc or bars 
###############################################################################
plota.candle <- function
(
	y,					# xts object to plot
	col = plota.candle.col(y)
)
{
	dx = plota.dx(y)
	# convert dx to line width
	dxi0 = ( dx / xinch() ) * 96

	if( dxi0 < 1 ) {
		plota.hl.lwd(y, col = col, lwd = 1)
	} else if ( dxi0 < 1.75 ) {
		plota.ohlc.lwd(y, col = col, lwd = 1)
	} else {
		temp.x = attr(y, 'index')
		
		rect(temp.x - dx/10, Lo(y), temp.x + dx/10, Hi(y), 
			col = plota.control$col.border, border = plota.control$col.border)
		rect(temp.x - dx/2, Op(y), temp.x + dx/2, Cl(y), 
			col = col, border = plota.control$col.border)	
	} 
}

###############################################################################
# plota.ohlc - plot ohlc
#  plota.ohlc will try to plot ohlc if dx is sufficient
#  otherwise ohlc or bars 
###############################################################################
plota.ohlc <- function
(
	y,					# xts object to plot
	col = plota.control$col.border
)
{
	dx = plota.dx(y)
	# convert dx to line width
	dxi0 = ( dx / xinch() ) * 96
		
	if( dxi0 < 1 ) {
		plota.hl.lwd(y, col = col, lwd = 1)
	} else if ( dxi0 < 1.75 ) {
		plota.ohlc.lwd(y, col = col, lwd = 1)
	} else {
		temp.x = attr(y, 'index')
		
		rect(temp.x - dx/8, Lo(y), temp.x + dx/8, Hi(y), col = col, border = col)
		segments(temp.x - dx/2, Op(y), temp.x, Op(y), col = col)	
		segments(temp.x + dx/2, Cl(y), temp.x, Cl(y), col = col)	
	}
}

###############################################################################
# plota.hl - plot hl
###############################################################################
plota.hl <- function
(
	y,					# xts object to plot
	col = plota.volume.col(y),
	border = plota.control$col.border
)
{
	dx = plota.dx(y)
	# convert dx to line width	
	dxi0 = ( dx / xinch() ) * 96
	
	if( dxi0 < 1.75 ) {
		plota.hl.lwd(y, col = col, lwd = 1)
	} else {
		temp.x = attr(y, 'index')
		
		rect(temp.x - dx/2, Lo(y), temp.x + dx/2, Hi(y), 
			col = col, border = border)
	}
}

###############################################################################
# plota.ohlc.lwd - plot ohlc using line width
###############################################################################
plota.ohlc.lwd <- function
(
	y,					# xts object to plot
	lwd=1,				# line width
	...					# other parameters to segments
)
{
	dx = plota.dx(y)
	temp.x = attr(y, 'index')	
	
	segments(temp.x, Lo(y), temp.x, Hi(y), lwd = lwd, lend = 2,  ...)
	segments(temp.x - dx/2, Op(y), temp.x, Op(y), lwd = lwd, lend = 2, ...)
	segments(temp.x + dx/2, Cl(y), temp.x, Cl(y), lwd = lwd, lend = 2, ...)
}

###############################################################################
# plota.hl.lwd - plot hl using line width
###############################################################################
plota.hl.lwd <- function
(
	y,					# xts object to plot
	lwd=1,				# line width
	...					# other parameters to segments
)
{
	temp.x = attr(y, 'index')	
	
	segments(temp.x, Lo(y), temp.x, Hi(y), lwd = lwd, lend = 2, ...)
}

###############################################################################
# plota.volume - plot volume
###############################################################################
plota.volume <- function
(
	y,							# xts object to plot
	col = plota.volume.col(y),	# color
	border = plota.control$col.border
)
{
	dx = plota.dx(y)
	# convert dx to line width
	dxi0 = ( dx / xinch() ) * 96
	
	temp.x = attr(y, 'index')	
	
	if( dxi0 < 1.75 ) {
		segments(temp.x, 0, temp.x, Vo(y), col = col, lwd = 1, lend = 2)	
	} else {
		rect(temp.x - dx/2, 0, temp.x + dx/2, Vo(y), 
			col = col, border = border)
	}
		
	idv = grep('Volume', colnames(y)) 
	temp = spl(colnames(y)[idv], ';')
	if( len(temp) > 1 ) legend('topright',legend = temp[len(temp)], bty='n');	
}

###############################################################################
# plota.scale.volume - scale volume, (c) quanmod package
###############################################################################
plota.scale.volume <- function(y) 
{
	Volumes = Vo(y)
	max.vol = max(Volumes, na.rm = T)
	vol.scale = list(100, '100s')
	if (max.vol > 10000) 
		vol.scale = list(1000, '1000s')
	if (max.vol > 1e+05) 
		vol.scale = list(10000, '10,000s')
	if (max.vol > 1e+06) 
		vol.scale = list(1e+05, '100,000s')
	if (max.vol > 1e+07) 
		vol.scale = list(1e+06, 'millions')
     
	idv = grep('Volume', colnames(y))
	y[, idv] = Volumes/vol.scale[[1]]
	colnames(y)[idv] = paste( colnames(y)[idv], vol.scale[[2]], sep=';' )
  	return(y)
}	


###############################################################################
# plota.test - test for plota functions
###############################################################################
plota.test <- function() {
	load.packages('quantmod')
	
	# download sample data from Yahoo
	data.spy = getSymbols('SPY', from = '1980-01-01', auto.assign = FALSE)
	data.ibm = getSymbols('IBM', from = '1980-01-01', auto.assign = FALSE)

	
	# simple example candles and volume	
		y = data.spy['2011:01:01::2011:02:01']
		highlight = which(Cl(y) < 127)

		png(filename = 'plot1.png', width = 500, height = 500, units = 'px', pointsize = 12, bg = 'white')
				
		layout(c(1,1,2))		
		plota(y, type = 'candle', main = 'SPY', plotX = F, x.highlight = highlight)
		y = plota.scale.volume(y)
		plota(y, type = 'volume', x.highlight = highlight)
		
		dev.off()

						
		
	# simple example + rsi + legend with last value		
		y = data.spy['2010:01:01::2011:02:01']		

		png(filename = 'plot2.png', width = 500, height = 500, units = 'px', pointsize = 12, bg = 'white')
				
		layout(c(1,1,2,3))	
		plota(y, type = 'candle', plotX = F)
			plota.legend('SPY', 'blue', y)
		y = plota.scale.volume(y)
		plota(y, type = 'volume', plotX = F)
			plota.legend('Volume', 'blue', Vo(y))
		rsi = RSI(Cl(y),2)
		plota(rsi, type = 'l', y.highlight = c(c(Inf,80),c(20,-Inf)))
			abline(h = 20, col = 'red')
			abline(h = 80, col = 'red')
			plota.legend('RSI(2)', 'black', rsi)
		
		dev.off()			
					
	# two Y axis example
		y = data.spy['2010:01:01::2011:02:01']
		
		png(filename = 'plot3.png', width = 500, height = 500, units = 'px', pointsize = 12, bg = 'white')
		
		# to plot second Y axis, free some space on left side
		# e.g. set LeftMargin=3
		plota(y, type = 'ohlc', LeftMargin=3)
			
		y0 = y;			
		y = data.ibm['2010:10:15::2011:02:01']		
		plota2Y(y, ylim = range(OHLC(y)),las=1, col='red', col.axis = 'red')
			plota.ohlc(y, col = 'red')		
		plota.legend('SPY(rhs),IBM(lhs)', 'blue,red', list(y0,y))

		dev.off()
				
	# daily & monthly  on the same plot
		y = data.spy['2010:01:01::2011:02:01']

		png(filename = 'plot4.png', width = 500, height = 500, units = 'px', pointsize = 12, bg = 'white')		
				
		plota(y, type = 'candle')
			y1 = to.monthly(y)
				index(y1) = as.Date(index(y1))
			plota.ohlc(y1, col = 'pink')
			plota.candle(y)
			plota.legend('Daily,Monthly', 'red,pink')
				
		dev.off()		
			
	# daily / weekly / monthly
		y = data.spy['2010:01:01::2011']
		
		png(filename = 'plot5.png', width = 500, height = 500, units = 'px', pointsize = 12, bg = 'white')		
		
		layout(c(1,2,3))	
		plota(y, type = 'candle', plotX = F)
			plota.legend('Daily', 'blue', y)
			
		plota(y, ylim = range(OHLC(y)), plotX = F)
			y1 = to.weekly(y)
				index(y1) = as.Date(index(y1))
			plota.candle(y1)			
			plota.legend('Weekly', 'blue', y1)		
			
		plota(y, ylim = range(OHLC(y)))
			y1 = to.monthly(y)
				index(y1) = as.Date(index(y1))
			plota.candle(y1)	
			plota.legend('Monthly', 'blue', y1)	
			
	dev.off()					
	
}



###############################################################################
# plota.staccked - staccked plot
###############################################################################
#col = rainbow(N, start=0, end=.9)
plota.colors <- function(N) {
	# default palette excluding black
	col = rev(c('yellow','cyan','magenta','red','gray','green','blue'))

	# find all available colors
	temp = list()
	for(j in 1:length(col)) {
		# find colors
		temp[[j]] = colors()[grep(col[j],colors())]
		
		# remove numbered colors
		temp[[j]] = temp[[j]][grep('^[^0-9]*$',temp[[j]])]

		# sort color names
		temp[[j]] = temp[[j]][order(nchar(temp[[j]]))]

		# remove 'white(255,255,255)' and 'black(0,0,0)'
		index = which( colSums(col2rgb(temp[[j]])) < 100 )
		if( length(index) > 0 ) temp[[j]] = temp[[j]][-index]

		index = which( colSums(255 - col2rgb(temp[[j]])) < 100 )
		if( length(index) > 0 ) temp[[j]] = temp[[j]][-index]
	}

	index = 1
	col = rep('', N)

	for(i in 1:10) {
		for(j in 1:length(temp)) {
			if(length(temp[[j]]) >= i) {
				col[index] = temp[[j]][i]
				index = index + 1
				if(index > N) break  
			}
		}
		if(index > N) break  
	}

	#pie(rep(1,length(1:14)), col=plota.colors(14))
	return(col)
}




plota.stacked <- function
(
	x,				# x data
	y, 				# matrix with y data : len(x) = nrow(y)
	xlab='',		# x axis label	
	col = plota.colors(ncol(y)), 	# colors
	type=c('l','s'),# plot type  : lines, step stairs
	...				# other parameters for plot
)
{

	# transform y
	y = 100 * y
	
	y1 = list()
	y1$positive = y
		y1$positive[ y1$positive < 0 ] = 0
	
	y1$negative = y
		y1$negative[ y1$negative > 0 ] = 0
		
	# find y ranges
	ylim = c(min(rowSums(y1$negative, na.rm = T)), max(1, rowSums(y1$positive, na.rm = T)))
	
	# create empty plot
	# par(mar = c(4, 4, 2, 1), cex = 0.8)
	if( class(x)[1] != 'Date' & class(x)[1] != 'POSIXct') {
		plot(x, rep(0, len(x)), ylim = ylim, t = 'n', xlab = '', ylab = '', cex = par('cex'), ...)
		grid()
	} else {
		#plot(x, rep(0, len(x)), ylim = ylim, t = 'n', yaxt = 'n', xaxt = 'n', xlab = '', ylab = '', cex = par('cex'), ...)
		#	axis(2)
		#	xaxis.ticks = axis.Date(1, x, labels = T, tick = T)		
		#	
		#	abline( h = axTicks(2), col = 'lightgray', lty = 'dotted')
		#	abline( v = xaxis.ticks, col = 'lightgray', lty = 'dotted')		
		
		plota(make.xts(y[,1], x), ylim = ylim, cex = par('cex'), LeftMargin = 4, ...)
		axis(2, las = 1) 
		x = unclass(as.POSIXct(x))
	}
		
	mtext('Allocation %', side = 2,line = 3, cex = par('cex'))
	mtext(xlab, side = 1,line = 2, cex = par('cex'))		
	
	
	# plot stacked areas	
	if( type[1] == 'l' ) {
		prep.x = c(x[1], x, x[len(x)])     
		
		for( y in y1 ) {   	
			for (i in ncol(y) : 1) {
		    	prep.y = c(0, rowSums(y[, 1 : i, drop = FALSE]), 0)
		    	polygon(prep.x, prep.y, col = col[i], border = NA, angle = 90)
			}
		}
    } else {
    	# http://r.789695.n4.nabble.com/how-to-fill-between-2-stair-plots-td819257.html
    	dx = mean(diff(x))
   		prep.x = c(rep(x,each=2), x[len(x)] + dx, x[len(x)] + dx)     
   		
   		for( y in y1 ) {   	
			for (i in ncol(y) : 1) {
		    	prep.y = c(0, rep(rowSums(y[, 1 : i, drop = FALSE]),each=2), 0)
		    	polygon(prep.x, prep.y, col = col[i], border = NA, angle = 90)
		    }    
		}
	} 

    # legend
    plota.legend(colnames(y), col, cex = par('cex'))    
}



###############################################################################
# plota.matplot plot lines stored in the matrix
###############################################################################
plota.matplot <- function
(
	y,				# xts object or list of xts objects to plot
	dates = NULL,	# dates subset	
	ylim = NULL,
	type = 'l',
	...				# other parameters for plot
)
{
	# find ylim	
	if( is.list(y) ) {
		if(!is.null(dates)) y[[1]] = y[[1]][dates]
		
		if(is.null(ylim)) {
			ylim = c()
			n = len(y)
			for( i in 1:n ) {
	   			if(!is.null(dates)) y[[i]] = y[[i]][dates]
				ylim = range(ylim, y[[i]], na.rm = T)
			}
		}
		
		plota(y[[1]], ylim = ylim, col = 1, type = type, ...)
		if( n > 1 ) {
			for( i in 2:n ) plota.lines(y[[i]], col = i, type = type, ...)
		}

		plota.legend(names(y), paste(1:n), y)	
				
	} else {
		n = ncol(y)
		if(!is.null(dates)) y = y[dates]
		if(is.null(ylim)) ylim = range(y, na.rm = T)
		
		plota(y[,1], ylim = ylim, col = 1, type = type, ...)
		if( n > 1 ) {
			for( i in 2:n ) plota.lines(y[,i], col = i, type = type, ...)
		}
		
		plota.legend(names(y), paste(1:n), as.list(y))	
	}	
}


###############################################################################
# Add recession bars 
# contributed by Judson Bishop <judson.bishop@gmail.com>
#
# SPY = getSymbols('SPY', auto.assign = F)
# plota(SPY, type='l')
# plota.recession()
###############################################################################
plota.recession <- function
(
	ylim = par('usr')[3:4]
)
{
	recessions.df = read.table(textConnection(
    "Peak, Trough
1857-06-01, 1858-12-01
1860-10-01, 1861-06-01
1865-04-01, 1867-12-01
1869-06-01, 1870-12-01
1873-10-01, 1879-03-01
1882-03-01, 1885-05-01
1887-03-01, 1888-04-01
1890-07-01, 1891-05-01
1893-01-01, 1894-06-01
1895-12-01, 1897-06-01
1899-06-01, 1900-12-01
1902-09-01, 1904-08-01
1907-05-01, 1908-06-01
1910-01-01, 1912-01-01
1913-01-01, 1914-12-01
1918-08-01, 1919-03-01
1920-01-01, 1921-07-01
1923-05-01, 1924-07-01
1926-10-01, 1927-11-01
1929-08-01, 1933-03-01
1937-05-01, 1938-06-01
1945-02-01, 1945-10-01
1948-11-01, 1949-10-01
1953-07-01, 1954-05-01
1957-08-01, 1958-04-01
1960-04-01, 1961-02-01
1969-12-01, 1970-11-01
1973-11-01, 1975-03-01
1980-01-01, 1980-07-01
1981-07-01, 1982-11-01
1990-07-01, 1991-03-01
2001-03-01, 2001-11-01
2007-12-01, 2009-06-01"),
	sep=',', colClasses=c('Date', 'Date'), header=TRUE)

	# The top of the recession rectangle
  	chart.max <- as.numeric(max(ylim))

  	# The bottom of the recession rectangle
  	chart.min <- as.numeric(min(ylim))

  	# Trim the recession dataframe to the same time length of the data
  	recessions.trim = subset(recessions.df, Peak >= as.Date(min(plota.control$xaxis.ticks)) )

  	# Set alpha = 50 so it's relatively transparent
  	color <- rgb(190, 190, 190, alpha=50, maxColorValue=255)

  	# Create the rectanble for recession
  	for(i in 1:length(recessions.trim$Peak)){
      	rect(xleft = as.POSIXct(recessions.trim$Peak[[i]]), 
      		xright = as.POSIXct(recessions.trim$Trough[[i]]), 
      		ybottom = chart.min, ytop = chart.max, col=color, border=color)
  	}
}

