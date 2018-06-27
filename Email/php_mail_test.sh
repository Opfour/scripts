<?php
$to = "wattersmt@gmail.com";
$subject = "Plain text e-mail";
$headers = "Content-Type: text/plain; charset=ISO-8859-1\r\n";
$body = "Hi,\n\nHow are you?";
if (mail($to, $subject, $body, $headers)) {
  echo("<p>Message successfully sent!</p>");
 } else {
  echo("<p>Message delivery failed...</p>");
 }
?>
