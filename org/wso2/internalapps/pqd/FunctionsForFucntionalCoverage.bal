package org.wso2.internalapps.pqd;

import ballerina.net.http;

function getAllAreaFuncCoverage () (json) {
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
