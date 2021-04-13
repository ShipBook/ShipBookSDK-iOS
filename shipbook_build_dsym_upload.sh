#!/bin/sh

#  shipbook_xc_build_dsym_upload..sh
#  MyShipBookClient
#
#  Created by Yuri Gen on 8/4/20.
#  Copyright © 2020 Shipbook Ltd. All rights reserved.
echo $BUILT_PRODUCTS_DIR

echo UPLOADING...

symbolsKey=$SHIPBOOK_SYMBOLS_KEY
buildProd=$BUILT_PRODUCTS_DIR
appId=$SHIPBOOK_APPID
prodName=$PRODUCT_NAME
filePath=$buildProd'/'$prodName'.app.dSYM'
buildNumber=$CURRENT_PROJECT_VERSION
marketingVersion=$MARKETING_VERSION


curl -X POST -H "Authorization: Bearer $symbolsKey" -F "data=@$filePath/Contents/Resources/DWARF/$PRODUCT_NAME" \
"https://api.shipbook.io/v1/apps/$appId/upload/dsym?version=$marketingVersion&build=$buildNumber"
