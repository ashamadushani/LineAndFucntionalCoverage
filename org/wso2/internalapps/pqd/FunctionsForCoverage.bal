package org.wso2.internalapps.pqd;

struct CoverageSnapshots {
    int snapshot_id;
}
struct Areas{
    int pqd_area_id;
    string pqd_area_name;
}

function getAllAreaCoverage()(json){
    json lineCoverageJson=getAllAreaLineCoverage();
    json functionalCoverageJson=getAllAreaFuncCoverage();
    json data = {"error":false, "data":{}};
    json coverageJson = {"items":[], "line_cov":{}, "func_cov":{}};
    int loopSize =lengthof lineCoverageJson.data.items;
    int index=0;

    while (index<loopSize) {
        json item={"name":lineCoverageJson.data.items[index].name,"id":lineCoverageJson.data.items[index].id,
                  "lc":lineCoverageJson.data.items[index].lc,"fc":functionalCoverageJson.data.items[index].fc};
        data.items[index] = item;

        index=index+1;
    }
    coverageJson.line_cov =lineCoverageJson.data.line_cov;
    coverageJson.func_cov=functionalCoverageJson.data.func_cov;
    data.data = coverageJson;
    return data;
}

function getSelectedAreaCoverage(int areaId)(json){
    json lineCoverageJson=getSelectedAreaLineCoverage(areaId);
    json functionalCoverageJson=getSelectedAreaFuncCoverage(areaId);
    json data={"error":false,"data":{}};
    json coverageJson = {"items":[], "line_cov":{}, "func_cov":{}};
    int loopSize =lengthof lineCoverageJson.data.items;
    int index=0;

    while (index<loopSize) {
        json item={"name":lineCoverageJson.data.items[index].name,"id":lineCoverageJson.data.items[index].id,
                      "lc":lineCoverageJson.data.items[index].lc,"fc":functionalCoverageJson.data.items[index].fc};
        data.items[index] = item;

        index=index+1;
    }
    coverageJson.line_cov =lineCoverageJson.data.line_cov;
    coverageJson.func_cov=functionalCoverageJson.data.func_cov;
    data.data = coverageJson;
    return coverageJson;
}

function getSelectedProductCoverage(int productId)(json){
    json lineCoverageJson=getSelectedProductLineCoverage(productId);
    json functionalCoverageJson=getSelectedProductFuncCoverage(productId);
    json data = {"error":false, "data":{}};
    json coverageJson = {"lc_items":[], "fc_items":[], "line_cov":{}, "func_cov":{}};
    coverageJson.lc_items = lineCoverageJson.data.items;
    coverageJson.fc_items = functionalCoverageJson.data.items;
    coverageJson.line_cov = lineCoverageJson.data.line_cov;
    coverageJson.func_cov = functionalCoverageJson.data.func_cov;
    data.data = coverageJson;
    return data;
}


function getDailyCoverageHistoryForAllArea (string start, string end) (json) {
    json lineCoverageJson=getDailyLineCoverageHistoryForAllArea(start,end);
    json functionalCoverageJson=getDailyFuncCoverageHistoryForAllArea(start,end);
}