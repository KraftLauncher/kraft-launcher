bool isIn5xx(int statusCode) => statusCode >= 500 && statusCode < 600;

bool isIn4xx(int statusCode) => statusCode >= 400 && statusCode < 500;

bool isIn2xx(int statusCode) => statusCode >= 200 && statusCode < 300;
