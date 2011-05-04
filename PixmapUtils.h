//
//  PixmapUtils.h
//  Creatures
//
//  Created by Michael Ash on Fri Jun 14 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


typedef struct
{
	unsigned char a, r, g, b;
} Pixel32;

typedef struct
{
	unsigned char r, g, b;
} Pixel24;

typedef union
{
	Pixel32 components;
	unsigned long value;
} PixelUnion;

void EncodePixel24(Pixel24 p, NSCoder *coder);
Pixel24 DecodePixel24(NSCoder *coder);

NSColor *ColorForPixel24(Pixel24 p);
Pixel24 Pixel24ForColor(NSColor *color);

void ClearPixmap(PixelUnion *pixmap, int xSize, int ySize);
void FillPixmap(PixelUnion *pixmap, PixelUnion pixel, int xSize, int ySize);
void FillRectangle(PixelUnion *pixmap, int xSize, int ulx, int uly, int lrx, int lry, PixelUnion fill);
void DrawHLine(PixelUnion *pixmap, int xSize, int lx, int ly, int rx, PixelUnion fill);
void DrawVLine(PixelUnion *pixmap, int xSize, int ux, int uy, int ly, PixelUnion fill);
//void DrawDiagLine(PixelUnion *pixmap, int xSize, int ulx, int uly, int xdir, int ydir

void RGBtoHSV( float r, float g, float b, float *h, float *s, float *v );
void HSVtoRGB( float *r, float *g, float *b, float h, float s, float v );
