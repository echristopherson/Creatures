//
//  PixmapUtils.m
//  Creatures
//
//  Created by Michael Ash on Fri Jun 14 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "PixmapUtils.h"

void EncodePixel24(Pixel24 p, NSCoder *coder)
{
	[coder encodeValueOfObjCType:@encode(int) at:&p.r];
	[coder encodeValueOfObjCType:@encode(int) at:&p.g];
	[coder encodeValueOfObjCType:@encode(int) at:&p.b];
}

Pixel24 DecodePixel24(NSCoder *coder)
{
	Pixel24 p;
	[coder decodeValueOfObjCType:@encode(int) at:&p.r];
	[coder decodeValueOfObjCType:@encode(int) at:&p.g];
	[coder decodeValueOfObjCType:@encode(int) at:&p.b];
	return p;
}

NSColor *ColorForPixel24(Pixel24 p)
{
	return [NSColor colorWithDeviceRed:p.r/255.0 green:p.g/255.0 blue:p.b/255.0 alpha:1.0];
}

Pixel24 Pixel24ForColor(NSColor *color)
{
	Pixel24 p;
	float r,g,b,a;
	[color getRed:&r green:&g blue:&b alpha:&a];
	p.r = r * 255;
	p.g = g * 255;
	p.b = b * 255;
	return p;
}

void ClearPixmap(PixelUnion *pixmap, int xSize, int ySize)
{
	int i;
	PixelUnion pixel = {{0}};
	pixel.components.a = 255;
	for(i = 0; i < xSize * ySize; i++)
	{
		pixmap[i] = pixel;
	}
}

void FillPixmap(PixelUnion *pixmap, PixelUnion pixel, int xSize, int ySize)
{
	int i;
	for(i = 0; i < xSize * ySize; i++)
	{
		pixmap[i] = pixel;
	}
}

void FillRectangle(PixelUnion *pixmap, int xSize, int ulx, int uly, int lrx, int lry, PixelUnion fill)
{
	PixelUnion *rowBase = pixmap + ulx + uly * xSize;
	int x, y;
	for(y = uly; y <= lry; y++)
	{
		PixelUnion *tempRow = rowBase;
		for(x = ulx; x <= lrx; x++)
		{
			*tempRow = fill;
			tempRow++;
		}
		rowBase += xSize;
	}
}

void DrawHLine(PixelUnion *pixmap, int xSize, int lx, int ly, int rx, PixelUnion fill)
{
	PixelUnion *rowBase = pixmap + lx + ly * xSize;
	int x;
	for(x = lx; x <= rx; x++)
	{
		*rowBase = fill;
		rowBase++;
	}
}

void DrawVLine(PixelUnion *pixmap, int xSize, int ux, int uy, int ly, PixelUnion fill)
{
	PixelUnion *rowBase = pixmap + ux + uy * xSize;
	int y;
	for(y = uy; y <= ly; y++)
	{
		*rowBase = fill;
		rowBase += xSize;
	}
}


// taken from http://www.cs.rit.edu/~ncs/color/t_convert.html

// r,g,b values are from 0 to 1
// h = [0,360], s = [0,1], v = [0,1]
//              if s == 0, then h = -1 (undefined)

void RGBtoHSV( float r, float g, float b, float *h, float *s, float *v )
{
	float min, max, delta;

	if(r < MIN(g,b))
		min = r;
	else
		min = MIN(g,b);

	if(r > MAX(g,b))
		max = r;
	else
		max = MAX(g,b);
	
	*v = max;                               // v

	delta = max - min;

	if( max != 0 )
		*s = delta / max;               // s
	else {
		// r = g = b = 0                // s = 0, v is undefined
		*s = 0;
		*h = -1;
		return;
	}

	if( r == max )
		*h = ( g - b ) / delta;         // between yellow & magenta
	else if( g == max )
		*h = 2 + ( b - r ) / delta;     // between cyan & yellow
	else
		*h = 4 + ( r - g ) / delta;     // between magenta & cyan

	*h *= 60;                               // degrees
	if( *h < 0 )
		*h += 360;
}

void HSVtoRGB( float *r, float *g, float *b, float h, float s, float v )
{
	int i;
	float f, p, q, t;

	if( s == 0 ) {
		// achromatic (grey)
		*r = *g = *b = v;
		return;
	}

	h /= 60;                        // sector 0 to 5
	i = floor( h );
	f = h - i;                      // factorial part of h
	p = v * ( 1 - s );
	q = v * ( 1 - s * f );
	t = v * ( 1 - s * ( 1 - f ) );

	switch( i ) {
		case 0:
			*r = v;
			*g = t;
			*b = p;
			break;
		case 1:
			*r = q;
			*g = v;
			*b = p;
			break;
		case 2:
			*r = p;
			*g = v;
			*b = t;
			break;
		case 3:
			*r = p;
			*g = q;
			*b = v;
			break;
		case 4:
			*r = t;
			*g = p;
			*b = v;
			break;
		default:                // case 5:
			*r = v;
			*g = p;
			*b = q;
			break;
	}
}