{ ... }:
{
  services.espanso = {
    enable = true;
    # configs = {};
    matches = {
      default = {
        matches = [
          {
            trigger = ":date";
            replace = "{date}";
            vars = [
              {
                name = "date";
                type = "date";
                format = "%d/%m/%Y";
              }
            ];
          }
          {
            trigger = ":datetime";
            replace = "{datetime}";
            vars = [
              {
                name = "datetime";
                type = "date";
                format = "%d/%m/%Y %H:%M:%S";
              }
            ];
          }
          {
            trigger = ":time";
            replace = "{time}";
            vars = [
              {
                name = "time";
                type = "date";
                format = "%H:%M:%S";
              }
            ];
          }
        ];
      };
    };
  };
}
