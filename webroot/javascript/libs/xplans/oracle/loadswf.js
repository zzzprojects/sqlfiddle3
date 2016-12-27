//
// This array should be modified everytime a new viewer is supported or when a
// new version of a viewer is introduced.
//
var viewerMap =
{
  "sqlmonitor" : [ "11" ],                                  // SQL monitor
  "sqlpa"      : [ "11" ],                                  // SPA
  "xplan"      : [ "11" ],                                  // xplan
  "sql_detail" : [ "11", "11.2.0.2.0" ],                    // SQL Details
  "EmergencyADDM" : [ "11" ],                               // Emergency ADDM
  "ComparePeriodReport" : [ "11" ],                         // Compare Period
  "AshViewer" : [ "11" ]                                    // ASH Viewer

};

// minimum version of the flash player we need
var requiredMajorVersion = 10;
var requiredMinorVersion = 0;
var requiredRevision     = 0;

// detect if flash player is available or not
var hasProductInstall = DetectFlashVer(6, 0, 65);
var hasRequestedVersion = DetectFlashVer(requiredMajorVersion,
                                         requiredMinorVersion,
                                         requiredRevision);

// the foolowing code is to better support browser history
Vars = function(qStr)
{
  this.numVars = 0;
  if(qStr != null)
  {
    var nameValue, name;
    var pairs = qStr.split('&');
    var pairLen = pairs.length;
    for(var i = 0; i < pairLen; i++)
    {
      var pair = pairs[i];
      if( (pair.indexOf('=')!= -1) && (pair.length > 3) )
      {
        var nameValue = pair.split('=');
        var name = nameValue[0];
        var value = nameValue[1];
        if(this[name] == null && name.length > 0 && value.length > 0)
        {
          this[name] = value;
          this.numVars++;
        }
      }
    }
  }
}

Vars.prototype.toString = function(pre)
{
  var result = '';
  if(pre == null) { pre = ''; }
  for(var i in this)
  {
    if(this[i] != null && typeof(this[i]) != 'object' &&
       typeof(this[i]) != 'function' && i != 'numVars')
    {
      result += pre + i + '=' + this[i] + '&';
    }
  }
  if(result.length > 0)
    result = result.substr(0, result.length-1);

  return result;
}

function getSearch(wRef)
{
  var searchStr = '';
  if(wRef.location.search.length > 1)
  {
    searchStr = new String(wRef.location.search);
    searchStr = searchStr.substring(1, searchStr.length);
  }
  return searchStr;
}


//
// parseVersion(): parse a version string assuming that a version has at most 5
//                 components (e.g. "11.1.0.0.1"). Missing components are
//                 assumed to be 0 (i.e. "11.2" is a shortcut for "11.2.0.0.0").
//
//                 Return an array of 5 numbers, one number per component version
//
function parseVersion(vString)
{
  // handle buggy values
  if (typeof(vString) != 'string')
    return [ 0, 0, 0, 0, 0 ];
  else
  {
    // parse string
    var x = vString.split('.');

    // parse from string or default to 0 if can't parse.
    // which is used for tests and maps to latest release
    var v0 = (x[0] == 'X') ? 999 : (parseInt(x[0]) || 0);
    var v1 = (x[1] == 'X') ? 999 : (parseInt(x[1]) || 0);
    var v2 = (x[2] == 'X') ? 999 : (parseInt(x[2]) || 0);
    var v3 = (x[3] == 'X') ? 999 : (parseInt(x[3]) || 0);
    var v4 = (x[4] == 'X') ? 999 : (parseInt(x[4]) || 0);

    // return
    return new Array( v0, v1, v2, v3, v4 );
  }
}

//
// compareVersions(): compare two version strings
//                    Return:
//                       -1 if v1 >  v2
//                        0 if v1 == v2
//                        1 if v1 <  v2
//
function compareVersions(v1String, v2String)
{
  // parse v1 and v2
  var v1 = parseVersion(v1String);
  var v2 = parseVersion(v2String);

  // compare the two versions
  for (var verComp = 0; verComp < 5; verComp++)
  {
    if (v1[verComp] < v2[verComp])
      return 1;
    else if (v1[verComp] > v2[verComp])
      return -1;
  }

  // must be equal
  return 0;
}


//
// findViewerFile(viewerName, xmlVersion): given viewer name and xml file
//                                         version, determine swf source file
//
function findViewerFile(viewerName, fileVersion)
{
  // determine object for that viewer
  var viewerVersions = viewerMap[viewerName];

  if (viewerVersions == null)
    return(false);

  // find appropriate version
  var nbVersions = viewerVersions.length;

  for (var verNum = 0; verNum < nbVersions; verNum++)
  {
    // found right version?
      if (compareVersions(viewerVersions[verNum], fileVersion) < 0)
          break;

  }

  if (verNum != 0) // choose the previous viewer version if any
      verNum--;

  var fileName = "http://download.oracle.com/otn_software/emviewers/" + viewerName + "/" + viewerVersions[verNum] +
                 "/" + viewerName;

  return fileName;
}

function loadswf(xml){

    // extract db_version and component name from the XML
    var matchVersion   = xml.match(/db_version="([\d\.]*)"/);
    var matchComponent = xml.match(/orarep\/(\w*)\//);

    // test for null
    var viewer_component  = (matchComponent == null)? '' : matchComponent[1];
    var viewer_db_version = (matchVersion == null)? ''   : matchVersion[1];

    // handle case when the report tag has not available
    if (viewer_component == '' &&
        xml.match(/sql_monitor_report/))
    {
      // assume first generation SQL monitor report
      viewer_component  = 'sqlmonitor';
      viewer_db_version = '11';
    }

    var lc_id = Math.floor(Math.random() * 100000).toString(16);
    if (this != top)
    {
      top.Vars = Vars;
      top.getSearch = getSearch;
      top.lc_id = lc_id;
    }

    var url_xml = 'historyUrl=history.htm%3F&lconid=' + lc_id +
                       '&model='+ encodeURIComponent(xml) +'';

    // main logic
    if ( hasProductInstall && !hasRequestedVersion )
    {
      var MMPlayerType = (isIE == true) ? "ActiveX" : "PlugIn";
      var MMredirectURL = window.location;
          document.title = document.title.slice(0, 47) +
          " - Flash Player Installation";
      var MMdoctitle = document.title;
      return AC_FL_RunContent(
        "src", "http://download.oracle.com/otn_software/emviewers/scripts/playerProductInstall",
        "FlashVars", url_xml,
        "width", "100%",
        "height", "100%",
        "align", "middle",
        "id", viewer_component,
        "quality", "high",
        "bgcolor", "#FFFFFF",
        "name", viewer_component,
        "allowScriptAccess","always",
        "type", "application/x-shockwave-flash",
        "pluginspage", "http://www.adobe.com/go/getflashplayer"
      );
    }
    else if (hasRequestedVersion)
    {
      // determine viewer swf file. Allow one to overwrite default using
      // viewer_swf variable
      var viewer_file = (typeof(viewer_swf) == 'string')?
            viewer_swf : findViewerFile(viewer_component, viewer_db_version);

      //  alert('Viewing file with ' + viewer_file);

      if (!viewer_file)
      {
        if (viewer_component != '')
          alert('Sorry, viewer name \"' + viewer_component +
                '\" is not yet supported...');
        else
          alert('Sorry, cannot not display report: unknown report type');
      }
      else
      {
        return AC_FL_RunContent(
          "src", viewer_file,
          "width", "100%",
          "height", "100%",
          "align", "middle",
          "id", viewer_component,
          "quality", "high",
          "bgcolor", "#FFFFFF",
          "name", viewer_component,
          "flashvars", url_xml,
          "allowScriptAccess","always",
          "type", "application/x-shockwave-flash",
          "pluginspage", "http://www.adobe.com/go/getflashplayer");
      }
    }
    else
    {
        var alternateContent = 'Fail to display EM Standalone report. '
        + 'This content requires the Adobe Flash Player. '
         + '<a href=http://www.adobe.com/go/getflash/>Get Flash</a>';
        return alternateContent;
    }

}


