<?php
// the optional info page (INFO_PAGE) : the operator's own HTML from InfoPage['File'], shown as is under the menu
$InfoFile = isset($PageOptions['InfoPage']['File']) ? $PageOptions['InfoPage']['File'] : '';
if (($InfoFile !== '') && is_file($InfoFile) && is_readable($InfoFile)) {
   readfile($InfoFile);
}
else {
   echo '
   <div class="error">
      The info page is switched on, but '.sanitize_output($InfoFile).' could not be read. Put your page in that file (INFO_PAGE_FILE).
   </div>';
}
?>
