/***************************************************************************
qgsmaptoolselectpolygon.cpp  -  map tool for selecting features by polygon
---------------------
begin                : May 2010
copyright            : (C) 2010 by Jeremy Palmer
email                : jpalmer at linz dot govt dot nz
***************************************************************************
*                                                                         *
*   This program is free software; you can redistribute it and/or modify  *
*   it under the terms of the GNU General Public License as published by  *
*   the Free Software Foundation; either version 2 of the License, or     *
*   (at your option) any later version.                                   *
*                                                                         *
***************************************************************************/

#include "qgsmaptoolselectpolygon.h"
#include "qgsmaptoolselectutils.h"
#include "qgsgeometry.h"
#include "qgsrubberband.h"
#include "qgsmapcanvas.h"
#include "qgis.h"

#include <QMouseEvent>


QgsMapToolSelectPolygon::QgsMapToolSelectPolygon( QgsMapCanvas* canvas )
    : QgsMapTool( canvas )
{
  mRubberBand = 0;
  mCursor = Qt::ArrowCursor;
  mFillColor = QColor( 254, 178, 76, 63 );
  mBorderColour = QColor( 254, 58, 29, 100 );
}

QgsMapToolSelectPolygon::~QgsMapToolSelectPolygon()
{
  delete mRubberBand;
}

void QgsMapToolSelectPolygon::canvasPressEvent( QMouseEvent * e )
{
  if ( mRubberBand == NULL )
  {
    mRubberBand = new QgsRubberBand( mCanvas, QGis::Polygon );
    //mRubberBand->setFillColor( mFillColor );
    //mRubberBand->setBorderColor( mBorderColour );

    // Serge Markin (serge@geoicon.com)
    // Modification for project edugis
    QSettings settings;
    int myRed = settings.value( "/qgis/default_selection_color_red", 180 ).toInt();
    int myGreen = settings.value( "/qgis/default_selection_color_green", 180 ).toInt();
    int myBlue = settings.value( "/qgis/default_selection_color_blue", 180 ).toInt();
    int myTransparency = settings.value( "/qgis/default_selection_transparency", 65 ).toInt();
    int myWidth = settings.value( "/qgis/default_selection_width", 2 ).toInt();
    mRubberBand->setFillColor( QColor( myRed, myGreen, myBlue, myTransparency ) );
    mRubberBand->setBorderColor( QColor( myRed, myGreen, myBlue, 100 ) );
    mRubberBand->setWidth(myWidth);
    // --------------------------------
  }
  if ( e->button() == Qt::LeftButton )
  {
    mRubberBand->addPoint( toMapCoordinates( e->pos() ) );
  }
  else
  {
    if ( mRubberBand->numberOfVertices() > 2 )
    {
      QgsGeometry* polygonGeom = mRubberBand->asGeometry();
      QgsMapToolSelectUtils::setSelectFeatures( mCanvas, polygonGeom, e );
      delete polygonGeom;
    }
    mRubberBand->reset( QGis::Polygon );
    delete mRubberBand;
    mRubberBand = 0;
  }
}

void QgsMapToolSelectPolygon::canvasMoveEvent( QMouseEvent * e )
{
  if ( mRubberBand == NULL )
  {
    return;
  }
  if ( mRubberBand->numberOfVertices() > 0 )
  {
    mRubberBand->removeLastPoint( 0 );
    mRubberBand->addPoint( toMapCoordinates( e->pos() ) );
  }
}

