# ProcessingVSido
## これは何？
[アスラテック株式会社](http://www.asratec.co.jp/ "アスラテック株式会社")のロボット制御マイコンボード「[V-Sido CONNECT RC](http://www.asratec.co.jp/product/connect/rc/ "V-Sido CONNECT RC")」をコントロールするためのProcessingのサンプルコードです。  
[V-Sido Developerサイトの技術資料](https://v-sido-developer.com/learning/connect/connect-rc/ "V-Sido Developerサイトの技術資料")に公開されている情報を元に、公式のUtilityを参考にして個人が作成したもので、アスラテック社公式のツールではありません。  
シリアル接続を経由して、V-Sido CONNECT用の各種コマンドの動作を確認することができます。

## 誰が作ったの？
アスラテック株式会社に勤務する今井大介(Daisuke IMAI)が個人として作成しました。

## どうして作ったの？
アスラテック社の用意している公式ツールはWindows用のもののみであり、プライベートで普段から使っているMacやUbuntuでもV-Sidoが使いたくて、ついカッとなって作ってしまいました。  

## 動作環境
Windows、OS X、Ubuntu上のProcessing 2.0以降で動作するのではないかと思います。  
動作確認済み環境は、
* Windows 8.1 + Processing 2.2.1
* OS X 10.10.3(Yosemite) + Processing 2.2.1
* Ubuntu 14.04 + Processing 2.2.1

UIのためにControlP5を利用しています。

## 使い方
ProcessingでProcessingVSido.pdeを開き実行してください。  
V-Sido CONNECT RCを有線もしくはBluetooth SPPでシリアル接続し、そのシリアルポートを指定して、CONNECTしてください。  
右上の「SHOW TX/RX LOG」をチェックしておくと、どのようなコマンドがやりとりされているかわかりやすいです。

## 免責事項
一応。  
  
このサンプルコードを利用して発生したいかなる損害についても、アスラテック株式会社ならびに今井大介は責任を負いません。自己責任での利用をお願いします。

## ライセンス
このサンプルコードは、GNU劣等GPLで配布します。  
  
Copyright (C)2015 Daisuke IMAI \<<hine.gdw@gmail.com>\>  

このライブラリはフリーソフトウェアです。あなたはこれを、フリーソフトウェア財団によって発行されたGNU 劣等一般公衆利用許諾契約書(バージョン2.1か、希望によってはそれ以降のバージョンのうちどれか)の定める条件の下で再頒布または改変することができます。  

このライブラリは有用であることを願って頒布されますが、*全くの無保証*です。商業可能性の保証や特定の目的への適合性は、言外に示されたものも含め全く存在しません。詳しくはGNU 劣等一般公衆利用許諾契約書をご覧ください。  

あなたはこのライブラリと共に、GNU 劣等一般公衆利用許諾契約書の複製物を一部受け取ったはずです。もし受け取っていなければ、フリーソフトウェア財団まで請求してください(宛先は the Free Software Foundation, Inc., 59Temple Place, Suite 330, Boston, MA 02111-1307 USA)。  


Copyright (C) 2015 Daisuke IMAI \<<hine.gdw@gmail.com>\>

This library is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation; either version 2.1 of the License, or (at your option) any later version.  

This library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.  

You should have received a copy of the GNU Lesser General Public License along with this library; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA  

