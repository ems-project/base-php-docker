<?php

if(isset($_ENV['DB_HOST']) && isset($_ENV['DB_DRIVER']) && isset($_ENV['DB_USER']) && isset($_ENV['DB_PASSWORD']) && isset($_ENV['DB_PORT']) && isset($_ENV['DB_NAME']))

{

        $driver = $_ENV['DB_DRIVER'];
        $dbname = $_ENV['DB_NAME'];
        $dbuser = $_ENV['DB_USER'];
        $dbpass = $_ENV['DB_PASSWORD'];
        $dbhost = $_ENV['DB_HOST'];
        $dbport = $_ENV['DB_PORT'];

        $link = mysqli_connect($dbhost, $dbuser, $dbpass, $dbname, $dbport) or die("Unable to Connect to '$dbhost'");
        mysqli_select_db($link, $dbname) or die("Could not open the db '$dbname'");

        $test_query = "SHOW TABLES FROM $dbname";
        $result = mysqli_query($link, $test_query);

        $tblCnt = 0;
        while($tbl = mysqli_fetch_array($result)) {
         $tblCnt++;
         #echo $tbl[0]."<br />\n";
        }

        if (!$tblCnt) {
            echo "There are no tables<br />\n";
        } else {
            echo "There are $tblCnt tables<br />\n";
        }

        echo "\n";
        echo "Check MySQL Connection Done.";

}
?>