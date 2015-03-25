#include "edugisutils.h"

#include <QLayout>
#include <QLayoutItem>
#include <QWidget>
#include <QRect>

EdugisUtils::EdugisUtils()
{
}


void EdugisUtils::hideLayout(QLayout * const layout)
{
  QRect nw(-1000, -1000, 0, 0);
  QWidget *widget;
  for (int i = 0, ii = layout->count(); i < ii; ++i)
  {
    QLayoutItem *item = layout->itemAt(i);
    widget = item->widget();
    if (widget)
    {
      widget->setGeometry(nw);
    }
  }
  widget = layout->parentWidget();
  if (widget && widget->layout())
  {
    widget->layout()->removeItem(layout);
  }
}
