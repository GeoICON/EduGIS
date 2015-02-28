#ifndef QGSCUSTOMABOUT_H
#define QGSCUSTOMABOUT_H

#include <QDialog>

namespace Ui {
class QgsCustomAbout;
}

class QgsCustomAbout : public QDialog
{
  Q_OBJECT
  
public:
  explicit QgsCustomAbout(QWidget *parent = 0);
  ~QgsCustomAbout();

   void setVersion(QString v);

private:
  Ui::QgsCustomAbout *ui;
};

#endif // QGSCUSTOMABOUT_H
