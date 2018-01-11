package org.wso2.internalapps.pqd;

import ballerina.util;
import ballerina.data.sql;
import ballerina.log;

struct TestProjects{
    string pqd_product_name;
    string testlink_project_name;
}

struct FunctionalCoverageDetails{
    string project_name;
    string test_plan_name;
    int total_features;
    int passed_features;
    int failed_features;
    int blocked_features;
    int not_run_features;
    float functional_coverage;
}

function getAllAreaFuncCoverage () (json) {
    endpoint<sql:ClientConnector> sqlEndPoint{}
    sql:ClientConnector sqlCon = getSQLConnectorForIssuesSonarRelease();
    bind sqlCon with sqlEndPoint;

    json data = {"error":false};
    json lineCoverage = {"items":[],"func_cov":{}};
    sql:Parameter[] params = [];

    datatable ssdt = sqlEndPoint.select(GET_FUNCCOVERAGE_SNAPSHOT_ID,params);
    CoverageSnapshots ss;
    int snapshot_id;
    TypeCastError err;
    while (ssdt.hasNext()) {
        any row = ssdt.getNext();
        ss, err = (CoverageSnapshots)row;
        snapshot_id= ss.snapshot_id;
    }
    ssdt.close();

    int totalFeatures = 0; int passedFeatures = 0; float functionalCoverage = 0.0;

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
        datatable pdt = sqlEndPoint.select(GET_TESTLINKPRODUCT_OF_AREA, params);
        TestProjects testProjects;
        while (pdt.hasNext()) {
            any row0 = pdt.getNext();
            testProjects, err = (TestProjects)row0;

            string project_name = testProjects.sonar_project_key;
            string product_name = testProjects.pqd_product_name;

            sql:Parameter sonar_project_key_para = {sqlType:sql:Type.VARCHAR, value:project_name};
            sql:Parameter snapshot_id_para = {sqlType:sql:Type.INTEGER, value:snapshot_id};
            params = [sonar_project_key_para,snapshot_id_para];
            datatable ldt = sqlEndPoint.select(GET_FUNC_COVERAGE_DETAILS, params);
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
        pdt.close();
        if(lines_to_cover!=0){
            line_coevrage=((float)covered_lines/(float)lines_to_cover)*100;
        }
        totalFeatures = totalFeatures + lines_to_cover;
        passedFeatures = passedFeatures + covered_lines;
        allAreaUncoveredLines=allAreaUncoveredLines+uncovered_lines;
        if(totalFeatures != 0) {
            functionalCoverage = ((float)passedFeatures / (float)totalFeatures) * 100;
        }
        json area_line_coverage = {"name":area_name, "id":area_id, "lc":{"lines_to_cover":lines_to_cover,"covered_lines":covered_lines,
                                                                            "uncovered_lines":uncovered_lines,"line_coverage":line_coevrage}};
        lineCoverage.items[lengthof lineCoverage.items]=area_line_coverage;
    }
    dt.close();
    lineCoverage.line_cov= {"lines_to_cover":totalFeatures, "covered_lines":passedFeatures,
                               "uncovered_lines":allAreaUncoveredLines,"line_coverage":functionalCoverage};


    data.data=lineCoverage;
    sqlEndPoint.close();
    return data;
}
