#include "qgscustomabout.h"
#include "ui_qgscustomabout.h"

QgsCustomAbout::QgsCustomAbout(QWidget *parent) :
  QDialog(parent),
  ui(new Ui::QgsCustomAbout)
{
  ui->setupUi(this);
}

QgsCustomAbout::~QgsCustomAbout()
{
  delete ui;
}

void QgsCustomAbout::setVersion( QString v )
{
    QString text = QString("<span style=\"font-size:16pt; color:#9c9c9c;\">version %1</span>").arg(v);
    ui->versionLabel->setText(text);
}
