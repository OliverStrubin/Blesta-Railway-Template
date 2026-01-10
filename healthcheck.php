<?php
http_response_code(200);
header('Content-Type: application/json');
echo json_encode([
  "ok" => true,
  "time" => date(DATE_ATOM),
]);
