package org.wso2.internalapps.pqd;

import ballerina.net.http;
import ballerina.util;
import ballerina.data.sql;
import ballerina.log;


struct Areas{
    int pqd_area_id;
    string pqd_area_name;
}

struct Components{
    int pqd_component_id;
    string pqd_component_name;
    int pqd_product_id;
    string sonar_project_key;
}

struct Products{
    int pqd_product_id;
    string pqd_product_name;
}

struct LinecoverageSnapshots{
    int snapshot_id;
}

struct LineCoverageDetails{
    int lines_to_cover;
    int covered_lines;
    int uncovered_lines;
    float line_coverage;
}
struct DailyLineCoverage{
    string date;
    int lines_to_cover;
    int covered_lines;
    int uncovered_lines;
    float line_coverage;
}

@http:configuration {
    basePath:"/internal/product-quality/v1.0/line-coverage",
    httpsPort:9092,
    keyStoreFile:"${ballerina.home}/bre/security/ballerinaKeystore.p12",
    keyStorePassword:"ballerina",
    certPassword:"ballerina",
    trustStoreFile:"${ballerina.home}/bre/security/ballerinaTruststore.p12",
    trustStorePassword:"ballerina",
    ciphers:"TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA",
    sslEnabledProtocols:"TLSv1.2,TLSv1.1"
}
service<http> LineCoverageService {
    json configData = getConfigData(CONFIG_PATH);

    @http:resourceConfig {
        methods:["GET"],
        path:"/fetch-data"
    }
    resource saveLineCoverageToDB (http:Request request, http:Response response) {
        http:HttpClient sonarCon = getHttpClientForSonar(configData);
        string path="/api/projects";
        json sonarResponse = getDataFromSonar(sonarCon,path,configData);
        saveLineCoverageToDatabase(sonarResponse,sonarCon,configData);
        response.setStringPayload("Fetchin data from sonar begun at "+currentTime().format("yyyy-MM-dd  HH:mm:ss"));
         _ = response.send();
    }

    @http:resourceConfig {
        methods:["GET"],
        path:"/{category}/{categoryId}"
    }
    resource getLineCoverage(http:Request request, http:Response response,string category, string categoryId){
        var selected,_=<int>categoryId;
        json returnJson;
        if(category=="all"){
           returnJson = getAllAreaLineCoverage();
        }else if(category=="area"){
            returnJson=getSelectedAreaLineCoverage(selected);
        }else if(category=="product"){
            returnJson=getSelectedProductLineCoverage(selected);
        }else if(category=="component"){
            returnJson=getSelectedComponentLineCoverage(selected);
        }else{
            returnJson={"error":true};
        }

        response.setJsonPayload(returnJson);
        _ = response.send();
    }

    @http:resourceConfig {
        methods:["GET"],
        path:"/history/{category}/{categoryId}"
    }
    resource getLineCoverageHistory(http:Request request,http:Response response, string category, string categoryId){
        json returnJson;
        map params = request.getQueryParams();
        var start,_=(string)params.dateFrom;
        var end,_=(string)params.dateTo;
        var period,_=(string)params.period;
        var selected,_=<int>categoryId;
        if(category=="all"){
            if(period=="day"){
                returnJson=getDailyLineCoverageHistoryForAllArea(start,end);
            }else if(period=="Month"){

            }else if(period=="Quarter"){

            }else if(period=="Year"){

            }else{
                returnJson={"error":true};
            }
        }else if(category=="area"){
            if(period=="day"){

            }else if(period=="Month"){

            }else if(period=="Quarter"){

            }else if(period=="Year"){

            }else{
                returnJson={"error":true};
            }
        }else if(category=="product"){
            if(period=="day"){

            }else if(period=="Month"){

            }else if(period=="Quarter"){

            }else if(period=="Year"){

            }else{
                returnJson={"error":true};
            }
        }else if(category=="component"){
            if(period=="day"){

            }else if(period=="Month"){

            }else if(period=="Quarter"){

            }else if(period=="Year"){

            }else{
                returnJson={"error":true};
            }
        }else{
            returnJson={"error":true};
        }

        response.setJsonPayload(returnJson);
        _ = response.send();
    }
}


function getAllAreaLineCoverage () (json) {
    endpoint<sql:ClientConnector> sqlEndPoint{}
    sql:ClientConnector sqlCon = getSQLConnectorForIssuesSonarRelease();
    bind sqlCon with sqlEndPoint;

    json data = {"error":false};
    json lineCoverage = {"items":[],"line_cov":{}};
    sql:Parameter[] params = [];

    datatable ssdt = sqlEndPoint.select(GET_LINECOVERAGE_SNAPSHOT_ID,params);
    LinecoverageSnapshots ss;
    int snapshot_id;
    TypeCastError err;
    while (ssdt.hasNext()) {
        any row = ssdt.getNext();
        ss, err = (LinecoverageSnapshots)row;
        snapshot_id= ss.snapshot_id;
    }
    ssdt.close();

    int allAreaLinesToCover=0; int allAreaCoveredLines=0; int allAreaUncoveredLines=0; float allAreaLineCoverage=0.0;

    datatable dt = sqlEndPoint.select(GET_ALL_AREAS, params);
    Areas area;

    while(dt.hasNext()) {
        any row1 =dt.getNext();
        area, err = (Areas)row1;

        string area_name = area.pqd_area_name;
        int area_id = area.pqd_area_id;

        int lines_to_cover=0; int covered_lines=0; int uncovered_lines=0; float line_coevrage=0.0;

        sql:Parameter pqd_area_id_para = {sqlType:sql:Type.INTEGER, value:area_id};
        params = [pqd_area_id_para];
        datatable cdt = sqlEndPoint.select(GET_COMPONENT_OF_AREA , params);
        Components comps;
        while (cdt.hasNext()) {
            any row0 = cdt.getNext();
            comps, err = (Components)row0;

            string project_key = comps.sonar_project_key;
            int component_id = comps.pqd_component_id;

            sql:Parameter sonar_project_key_para = {sqlType:sql:Type.VARCHAR, value:project_key};
            sql:Parameter snapshot_id_para = {sqlType:sql:Type.INTEGER, value:snapshot_id};
            params = [sonar_project_key_para,snapshot_id_para];
            datatable ldt = sqlEndPoint.select(GET_LINE_COVERAGE_DETAILS, params);
            LineCoverageDetails lcd;
            while (ldt.hasNext()) {
                any row2 = ldt.getNext();
                lcd, err = (LineCoverageDetails )row2;
                lines_to_cover=lcd.lines_to_cover+lines_to_cover;
                covered_lines=lcd.covered_lines+covered_lines;
                uncovered_lines=lcd.uncovered_lines+uncovered_lines;
            }
            ldt.close();
        }
        cdt.close();
        if(lines_to_cover!=0){
                line_coevrage=((float)covered_lines/(float)lines_to_cover)*100;
        }
        allAreaLinesToCover=allAreaLinesToCover+lines_to_cover;
        allAreaCoveredLines=allAreaCoveredLines+covered_lines;
        allAreaUncoveredLines=allAreaUncoveredLines+uncovered_lines;
        if(allAreaLinesToCover!=0){
                allAreaLineCoverage=((float)allAreaCoveredLines /(float)allAreaLinesToCover) * 100;
        }
        json area_line_coverage = {"name":area_name, "id":area_id, "lc":{"lines_to_cover":lines_to_cover,"covered_lines":covered_lines,
                                                                        "uncovered_lines":uncovered_lines,"line_coverage":line_coevrage}};
        lineCoverage.items[lengthof lineCoverage.items]=area_line_coverage;
    }
    dt.close();
    lineCoverage.line_cov= {"lines_to_cover":allAreaLinesToCover,"covered_lines":allAreaCoveredLines,
                                 "uncovered_lines":allAreaUncoveredLines,"line_coverage":allAreaLineCoverage};


    data.data=lineCoverage;
    sqlEndPoint.close();
    return data;
}

function getSelectedAreaLineCoverage (int areaId) (json) {
    endpoint<sql:ClientConnector> sqlEndPoint{}
    sql:ClientConnector sqlCon = getSQLConnectorForIssuesSonarRelease();
    bind sqlCon with sqlEndPoint;

    json data = {"error":false};
    json lineCoverage = {"items":[],"line_cov":{}};
    sql:Parameter[] params = [];

    datatable ssdt = sqlEndPoint.select(GET_LINECOVERAGE_SNAPSHOT_ID,params);
    LinecoverageSnapshots ss;
    int snapshot_id;
    TypeCastError err;
    while (ssdt.hasNext()) {
        any row = ssdt.getNext();
        ss, err = (LinecoverageSnapshots)row;
        snapshot_id= ss.snapshot_id;
    }
    ssdt.close();

    sql:Parameter areaIdPara={sqlType:sql:Type.INTEGER,value:areaId};
    params=[areaIdPara];

    int selectedAreaLinesToCover = 0; int selectedAreaCoveredLines = 0;
    int selectedAreaUncoveredLines = 0; float selectedAreaLineCoverage = 0.0;

    datatable dt = sqlEndPoint.select(GET_PRODUCTS_OF_AREA, params);
    Products product;

    while(dt.hasNext()) {
        any row1 =dt.getNext();
        product, err = (Products)row1;

        string product_name = product.pqd_product_name;
        int product_id = product.pqd_product_id;

        int lines_to_cover=0; int covered_lines=0; int uncovered_lines=0; float line_coevrage=0.0;

        sql:Parameter pqd_product_id_para = {sqlType:sql:Type.INTEGER, value:product_id};
        params = [pqd_product_id_para];
        datatable cdt = sqlEndPoint.select(GET_COMPONENT_OF_PRODUCT , params);
        Components comps;
        while (cdt.hasNext()) {
            any row0 = cdt.getNext();
            comps, err = (Components)row0;

            string project_key = comps.sonar_project_key;
            int component_id = comps.pqd_component_id;

            sql:Parameter sonar_project_key_para = {sqlType:sql:Type.VARCHAR, value:project_key};
            sql:Parameter snapshot_id_para = {sqlType:sql:Type.INTEGER, value:snapshot_id};
            params = [sonar_project_key_para,snapshot_id_para];
            datatable ldt = sqlEndPoint.select(GET_LINE_COVERAGE_DETAILS, params);
            LineCoverageDetails lcd;
            while (ldt.hasNext()) {
                any row2 = ldt.getNext();
                lcd, err = (LineCoverageDetails )row2;
                lines_to_cover=lcd.lines_to_cover+lines_to_cover;
                covered_lines=lcd.covered_lines+covered_lines;
                uncovered_lines=lcd.uncovered_lines+uncovered_lines;
            }
            ldt.close();
        }
        cdt.close();
        if(lines_to_cover!=0){
            line_coevrage=((float)covered_lines/(float)lines_to_cover)*100;
        }
        selectedAreaLinesToCover = selectedAreaLinesToCover + lines_to_cover;
        selectedAreaCoveredLines = selectedAreaCoveredLines + covered_lines;
        selectedAreaUncoveredLines = selectedAreaUncoveredLines + uncovered_lines;
        if(selectedAreaLinesToCover != 0) {
            selectedAreaLineCoverage = ((float)selectedAreaCoveredLines / (float)selectedAreaLinesToCover) * 100;
        }
        json product_line_coverage = {"name":product_name, "id":product_id, "lc":{"lines_to_cover":lines_to_cover,"covered_lines":covered_lines,
                                                                            "uncovered_lines":uncovered_lines,"line_coverage":line_coevrage}};
        lineCoverage.items[lengthof lineCoverage.items]=product_line_coverage;
    }
    dt.close();
    lineCoverage.line_cov= {"lines_to_cover":selectedAreaLinesToCover, "covered_lines":selectedAreaCoveredLines,
                                 "uncovered_lines":selectedAreaUncoveredLines, "line_coverage":selectedAreaLineCoverage};


    data.data=lineCoverage;
    sqlEndPoint.close();
    return data;
}

function getSelectedProductLineCoverage (int productId) (json) {
    endpoint<sql:ClientConnector> sqlEndPoint{}
    sql:ClientConnector sqlCon = getSQLConnectorForIssuesSonarRelease();
    bind sqlCon with sqlEndPoint;

    json data = {"error":false};
    json lineCoverage = {"items":[],"line_cov":{}};
    sql:Parameter[] params = [];

    datatable ssdt = sqlEndPoint.select(GET_LINECOVERAGE_SNAPSHOT_ID,params);
    LinecoverageSnapshots ss;
    int snapshot_id;
    TypeCastError err;
    while (ssdt.hasNext()) {
        any row = ssdt.getNext();
        ss, err = (LinecoverageSnapshots)row;
        snapshot_id= ss.snapshot_id;
    }
    ssdt.close();


    int selectedProductLinesToCover = 0; int selectedProductCoveredLines = 0;
    int selectedProductUncoveredLines = 0; float selectedProductLineCoverage = 0.0;

    sql:Parameter pqd_product_id_para = {sqlType:sql:Type.INTEGER, value:productId};
    params = [pqd_product_id_para];
    datatable cdt = sqlEndPoint.select(GET_COMPONENT_OF_PRODUCT , params);
    Components comps;
    while (cdt.hasNext()) {
        any row0 = cdt.getNext();
        comps, err = (Components)row0;

        string component_name=comps.pqd_component_name;
        string project_key = comps.sonar_project_key;
        int component_id = comps.pqd_component_id;

        int lines_to_cover=0; int covered_lines=0; int uncovered_lines=0; float line_coevrage=0.0;

        sql:Parameter sonar_project_key_para = {sqlType:sql:Type.VARCHAR, value:project_key};
        sql:Parameter snapshot_id_para = {sqlType:sql:Type.INTEGER, value:snapshot_id};
        params = [sonar_project_key_para,snapshot_id_para];
        datatable ldt = sqlEndPoint.select(GET_LINE_COVERAGE_DETAILS, params);
        LineCoverageDetails lcd;
        while (ldt.hasNext()) {
            any row2 = ldt.getNext();
            lcd, err = (LineCoverageDetails )row2;
            lines_to_cover=lcd.lines_to_cover;
            covered_lines=lcd.covered_lines;
            uncovered_lines=lcd.uncovered_lines;
        }
        ldt.close();
        if(lines_to_cover!=0){
            line_coevrage=((float)covered_lines/(float)lines_to_cover)*100;
        }
        json component_line_coverage = {"name":component_name, "id":component_id, "lc":{"lines_to_cover":lines_to_cover, "covered_lines":covered_lines,
                                                                                       "uncovered_lines":uncovered_lines,"line_coverage":line_coevrage}};
        lineCoverage.items[lengthof lineCoverage.items]= component_line_coverage;
        selectedProductLinesToCover = selectedProductLinesToCover + lines_to_cover;
        selectedProductCoveredLines = selectedProductCoveredLines + covered_lines;
        selectedProductUncoveredLines = selectedProductUncoveredLines + uncovered_lines;
    }
    cdt.close();

    if(selectedProductLinesToCover != 0) {
        selectedProductLineCoverage = ((float)selectedProductCoveredLines / (float)selectedProductLinesToCover) * 100;
    }

    lineCoverage.line_cov= {"lines_to_cover":selectedProductLinesToCover, "covered_lines":selectedProductCoveredLines,
                                 "uncovered_lines":selectedProductUncoveredLines, "line_coverage":selectedProductLineCoverage};

    data.data=lineCoverage;
    sqlEndPoint.close();
    return data;
}

function getSelectedComponentLineCoverage (int componentId) (json) {
    endpoint<sql:ClientConnector> sqlEndPoint{}
    sql:ClientConnector sqlCon = getSQLConnectorForIssuesSonarRelease();
    bind sqlCon with sqlEndPoint;

    json data = {"error":false};
    json lineCoverage = {"items":[],"line_cov":{}};
    sql:Parameter[] params = [];

    datatable ssdt = sqlEndPoint.select(GET_LINECOVERAGE_SNAPSHOT_ID,params);
    LinecoverageSnapshots ss;
    int snapshot_id;
    TypeCastError err;
    while (ssdt.hasNext()) {
        any row = ssdt.getNext();
        ss, err = (LinecoverageSnapshots)row;
        snapshot_id= ss.snapshot_id;
    }
    ssdt.close();


    int selectedComponentLinesToCover = 0; int selectedComponentCoveredLines = 0;
    int selectedComponentUncoveredLines = 0; float selectedComponentLineCoverage = 0.0;

    sql:Parameter pqd_product_id_para = {sqlType:sql:Type.INTEGER, value:componentId};
    params = [pqd_product_id_para];
    datatable cdt = sqlEndPoint.select(GET_DETAILS_OF_COMPONENT , params);
    Components comps;
    while (cdt.hasNext()) {
        any row0 = cdt.getNext();
        comps, err = (Components)row0;

        string project_key = comps.sonar_project_key;

        sql:Parameter sonar_project_key_para = {sqlType:sql:Type.VARCHAR, value:project_key};
        sql:Parameter snapshot_id_para = {sqlType:sql:Type.INTEGER, value:snapshot_id};
        params = [sonar_project_key_para,snapshot_id_para];
        datatable ldt = sqlEndPoint.select(GET_LINE_COVERAGE_DETAILS, params);
        LineCoverageDetails lcd;
        while (ldt.hasNext()) {
            any row2 = ldt.getNext();
            lcd, err = (LineCoverageDetails )row2;
            selectedComponentLinesToCover=lcd.lines_to_cover;
            selectedComponentCoveredLines=lcd.covered_lines;
            selectedComponentUncoveredLines=lcd.uncovered_lines;
        }
        ldt.close();
        if(selectedComponentLinesToCover != 0) {
            selectedComponentLineCoverage = ((float)selectedComponentCoveredLines / (float)selectedComponentLinesToCover) * 100;
        }
    }
    cdt.close();

    lineCoverage.line_cov= {"lines_to_cover":selectedComponentLinesToCover, "covered_lines":selectedComponentCoveredLines,
                                 "uncovered_lines":selectedComponentUncoveredLines, "line_coverage":selectedComponentLineCoverage};

    data.data=lineCoverage;
    sqlEndPoint.close();
    return data;
}

function getDailyLineCoverageHistoryForAllArea(string start,string end)(json){
    endpoint<sql:ClientConnector> sqlEndPoint {
    }

    sql:ClientConnector sqlCon = getSQLConnectorForIssuesSonarRelease();
    bind sqlCon with sqlEndPoint;

    json data = {"error":false,"data":[]};
    json allAreasLineCoverage = {"data":[]};
    sql:Parameter[] params = [];
    TypeCastError err;

    sql:Parameter start_date_para = {sqlType:sql:Type.VARCHAR, value:start};
    sql:Parameter end_date_para = {sqlType:sql:Type.VARCHAR, value:end};
    params = [start_date_para,end_date_para];
    datatable ldt = sqlEndPoint.select(GET_ALL_AREA_DAILY_LINE_COVERAGE, params);
    DailyLineCoverage dlc;
    while(ldt.hasNext()){
        any row=ldt.getNext();
        dlc,err=(DailyLineCoverage )row;
        string date= dlc.date;
        int lines_to_cover=dlc.lines_to_cover;
        int covered_lines=dlc.covered_lines;
        int uncovered_lines=dlc.uncovered_lines;
        float line_coverage=dlc.line_coverage;
        json history={"date":date,"lines_to_cover":lines_to_cover,"covered_lines":covered_lines,
                         "uncovered_lines":uncovered_lines,"line_coverage":line_coverage};
        allAreasLineCoverage.data[lengthof allAreasLineCoverage.data]=history;
    }
    ldt.close();

    data.data=allAreasLineCoverage.data;
    sqlEndPoint.close();
    return data;
}

function saveLineCoverageToDatabase (json projects,http:HttpClient sonarcon,json configData)  {
    endpoint<sql:ClientConnector> sqlEndPoint {}

    worker issuesRecordingWorker {

        sql:ClientConnector sqlCon = getSQLConnectorForIssuesSonarRelease();
        bind sqlCon with sqlEndPoint;

        int lengthOfProjectList = lengthof projects;
        sql:Parameter[] params = [];

        string customStartTimeString = currentTime().format("yyyy-MM-dd");
        sql:Parameter todayDate = {sqlType:sql:Type.VARCHAR, value:customStartTimeString};
        params = [todayDate];

        int ret =0;
        try{
            ret=sqlEndPoint.update(INSERT_LINECOVERAGE_SNAPSHOT_DETAILS, params);
        }catch(error conErr){
            log:printError(conErr.msg);
        }

        if(ret != 0){
            params = [];
            datatable dt = sqlEndPoint.select(GET_LINECOVERAGE_SNAPSHOT_ID, params);
            LinecoverageSnapshots ss;
            int snapshot_id;
            TypeCastError err;
            while (dt.hasNext()) {
                any row = dt.getNext();
                ss, err = (LinecoverageSnapshots )row;
                snapshot_id = ss.snapshot_id;
            }
            dt.close();

            sql:Parameter snapshotid = {sqlType:sql:Type.INTEGER, value:snapshot_id};
            int index = 0;
            log:printInfo("Fetching data from SonarQube started at " + currentTime().format("yyyy-MM-dd  HH:mm:ss") + ". There are " + lengthOfProjectList + " sonar projectts for this time.");
            //transaction {
                while (index < lengthOfProjectList) {
                    var project_key, _ = (string)projects[index].k;
                    sql:Parameter projectkey = {sqlType:sql:Type.VARCHAR, value:project_key};
                    log:printInfo(index + 1 + ":" + "Fetching line coverage details for project " + project_key);
                    json lineCoveragePerProject = getLineCoveragePerProjectFromSonar(project_key, sonarcon, configData);

                    var emptyJson,_ =(boolean)lineCoveragePerProject.error;

                    if(!emptyJson){
                        var lines_to_cover,_ = (float)lineCoveragePerProject.lines_to_cover;
                        var uncovered_lines,_ = (float)lineCoveragePerProject.uncovered_lines;
                        var line_coverage,_ = (float)lineCoveragePerProject.line_coverage;
                        float covered_lines = lines_to_cover - uncovered_lines;

                        sql:Parameter lines_to_cover_para = {sqlType:sql:Type.FLOAT,value:lines_to_cover};
                        sql:Parameter covered_lines_para={sqlType:sql:Type.FLOAT,value:covered_lines};
                        sql:Parameter uncovered_linese_para={sqlType:sql:Type.FLOAT,value:uncovered_lines};
                        sql:Parameter line_coverage_para={sqlType:sql:Type.FLOAT,value:line_coverage};

                        params = [snapshotid, todayDate, projectkey, lines_to_cover_para,covered_lines_para,uncovered_linese_para,line_coverage_para];
                        log:printInfo("Line coverage details were recoded successfully..");
                        int ret1 = sqlEndPoint.update(INSERT_DAILY_LINE_COVERAGE_DETAILS, params);
                    }

                    index = index + 1;
                }
            //}committed{
                string customEndTimeString = currentTime().format("yyyy-MM-dd  HH:mm:ss");
                log:printInfo("Data fetching from sonar finished at " + customEndTimeString);
            //}
        }
        sqlEndPoint.close();
    }
}

function getLineCoveragePerProjectFromSonar(string project_key,http:HttpClient sonarcon,json configData)(json){
    string path = "/api/resources?metrics=lines_to_cover,uncovered_lines,line_coverage&format=json&resource="+ project_key;
    log:printInfo("Getting line coverage for "+project_key);
    json sonarJSONResponse = getDataFromSonar(sonarcon,path,configData);
    json returnJson={"error":true};
    int jsonObjectLength=-1;
    try{
        string err_code="";
        if(lengthof sonarJSONResponse == jsonObjectLength){
           err_code ,_ = (string)sonarJSONResponse.err_code;
        }

        if(err_code != "404" && lengthof sonarJSONResponse != jsonObjectLength){
            if(sonarJSONResponse[0].msr!=null){
                var lines_to_cover,_ =(float)sonarJSONResponse[0].msr[0].val;
                var uncovered_lines,_ =(float)sonarJSONResponse[0].msr[1].val;
                var line_coverage,_ =(float)sonarJSONResponse[0].msr[2].val;
                returnJson={"error":false,"lines_to_cover":lines_to_cover,"uncovered_lines":uncovered_lines,"line_coverage":line_coverage};
            }
        }
    }catch(error err){
        log:printError(err.msg);
    }
    return returnJson;
}

function getDataFromSonar(http:HttpClient httpCon, string path,json configData)(json){
    endpoint<http:HttpClient> httpEndPoint {
        httpCon;
    }
    log:printDebug("getDataFromSonar function got invoked for path : " + path);
    http:Request req = {};
    http:Response resp = {};
    http:HttpConnectorError conErr;
    authHeader(req,configData);
    resp, conErr = httpEndPoint.get(path, req);
    if(conErr != null){
        log:printError(conErr.msg);
    }
    json returnJson={};
    try {
        returnJson = resp.getJsonPayload();
    }catch(error err){
        log:printError(err.msg);
    }
    return returnJson;
}

function getHttpClientForSonar(json configData)(http:HttpClient){
    var basicurl,_=(string)configData.SONAR.SONAR_URL;
    http:HttpClient sonarCon=create http:HttpClient(basicurl,{});
    return sonarCon;
}

function authHeader (http:Request req,json configData) {
    string sonarAccessToken;
    sonarAccessToken, _ = (string)configData.SONAR.SONAR_ACCESS_TOKEN;
    string token=sonarAccessToken+":";
    string encodedToken = util:base64Encode(token);
    string passingToken = "Basic "+encodedToken;
    req.setHeader("Authorization", passingToken);
    req.setHeader("Content-Type", "application/json");

}
