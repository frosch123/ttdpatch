#ifndef __GRIDARRAY_H__
#define __GRIDARRAY_H__

/*
* Adam Kadlubek 2006
* Terrain Generator for TTD
* under GPL license
* version written in C, not protable
* to C++
*
* This is actually a refactor of a C++ class
* that is why all ex-methods have the explicit
* 'this_' pointer
*/

typedef unsigned long ulong;
typedef unsigned  int uint;

#define NOBMP /* undefining this requires
compliation as C++ as BMP is a class */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

typedef struct {

	float** data; /* data array */
        
        ulong size_x; /* size of the array */
        ulong size_y; /* size of the array */
} gridArray;

#ifdef __GNUC__
	#define INLINE static inline
	#define INLINE_DEF
#else
	#define INLINE
#endif

void snipArray (gridArray* source_,ulong  size_x_,ulong  size_y_,gridArray** this_);
/* copy constructor for creating the array from another
   array with its sub-cutted elements */

void makeArray (ulong size_x_, ulong size_y_,uint32_t (*randomizer)(void), gridArray** this_);
/* construct an array of a given size */

void destroyArray(gridArray** this_);
/* destructor of the array */

void mulArray(gridArray* source_,gridArray* this_);
/* multiply elements of one array with elements of this_ array*/

void mulScalar (float scalar, gridArray* this_);
/* scalar multiply operator */

void addArray(gridArray* _source, gridArray* this_);
/* addition of two arrays */

void addScalar(float scalar, gridArray* this_);
/* addition of a value to all array elements */

void scale(ulong newSize_x, ulong newSize_y, gridArray** this_);
/* scale the given array to a new size */

void filter(ulong iterations, gridArray** this_);
/* smooth the given array by x times using bilinear filtering */

void go(ulong iterations, gridArray** this_);
/* do the generation using the iterations set by the user */

void normalize(float hi, gridArray* this_);
/* normalize the array to the low-hi range */

#ifndef NOBMP
void image(const char* filename, gridArray* this_);
/* inputs the map as a bmp image */
#endif

void ttMap(ulong cutDown, ulong cutUp, gridArray* this_);
/* change the map to fulfill the Transport
   Tycoon requirements for the vertex data */

void ttDesert(gridArray* target, ulong min, ulong max, ulong rfmin, ulong range, gridArray* this_);
/* make TT desert */

void print (gridArray* this_);
/* print the contents of the array */

void shift_x (int dir, ulong row, gridArray* this_);
/* move values by 1 on thr x axis */

void shift_y (int dir, ulong row, gridArray* this_);
/* move values by q on the y axis */

/* in both cases - if dir is negative, shift low->hi
else shift hi->lo */


int recursiveTest(ulong range, ulong x, ulong y, gridArray* this_);
/* recursive test of whether a tile can be a desert tile
	 needs an improvement to seek a circual pattern and not
	 a 'star' like currently */

/*
*
* return size of the array
*
*/

#ifdef INLINE_DEF
INLINE ulong size_x(gridArray* this_)
{
  return this_->size_x;
}

/*
*
* likewise
*
*/

INLINE ulong size_y(gridArray* this_)
{
  return this_->size_y;
}

/*
*
* return value under indices
*
*/

INLINE float val (ulong i_x, ulong i_y, gridArray* this_)
{

  if (size_x(this_) <= i_x || size_y(this_) <= i_y)
    return -1000000.0;

  return this_->data[i_x][i_y];
}

/*
*
* insert value under indices
*
*/

INLINE void insert (float val,ulong i_x, ulong i_y, gridArray* this_)
{
  if (size_x(this_) > i_x && size_y(this_) > i_y)
    this_->data[i_x][i_y] = val;
}

/*
*
* make sure value differs no more than 1 from neighbour
*
*/

INLINE void adjust (ulong i_x, ulong i_y, ulong j_x, ulong j_y, int raise, gridArray* this_)
{
  long current = (long)(val(i_x,i_y,this_));
  long prev    = (long)(val(j_x,j_y,this_));

  if (raise) {
    if (current > prev + 1)
      insert (current - 1, j_x, j_y, this_);
    if (current + 1 < prev)
      insert (prev - 1, i_x, i_y, this_);
  } else {
    if (current > prev + 1)
      insert (prev + 1, i_x, i_y, this_);
    else if (current + 1 < prev)
      insert (current + 1, j_x, j_y, this_);
  }
}

/*
*
* check if two verices are close/far away.
* needed for scaling
*
*/

INLINE int dist(ulong otherSize, ulong other, ulong mySize, ulong indice, gridArray* this_) {

  float len = 0.0;
  float my = indice *1.0 /mySize;
  float ot = other  *1.0 /otherSize;

  len = (ot-my)*mySize*1.0;
  return (len < 1.0);
}
#else
INLINE ulong size_x(gridArray* this_);
INLINE ulong size_y(gridArray* this_);
INLINE float val (ulong i_x, ulong i_y, gridArray* this_);
INLINE void insert (long float val,ulong i_x, ulong i_y, gridArray* this_);
INLINE void test (long* current, long* prev);
INLINE int dist(ulong otherSize, ulong other, ulong mySize, ulong indice, gridArray* this_);
#endif

/*
*
* Stencils
*
*/

void stencil (float stencil_data[16][16], gridArray** this_);

extern float valley_data[16][16];

#endif
