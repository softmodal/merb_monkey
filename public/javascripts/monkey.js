/////////////////////////////////////////////////
//GLOBALS////////////////////////////////////////
/////////////////////////////////////////////////
var monkey = {
  autocomplete: {},
  clear_data: function() {
    $.each(this.models, function(i, obj) {
      obj.data = [];
    });
  },
  count: 0,
  prefix: "",
  models: {},
  partial: {
    element: function(model_name, property, property_name) {
      var readonly = "";
      if (property.readonly) readonly = " disabled";
      var name = model_name.toLowerCase() + "[" + property.setter + "]";
      var name = "obj[" + property.setter + "]";
      var id = property_name;
      var str = "";
      var type = property.type;
      if (type == "checkbox") {
        str = "<input id='" + id + "_' type='hidden' value='0' name='" + name + "'" + readonly + " />";
        str += "<input id='" + id + "' type='checkbox' value='1' name='" + name + "'" + readonly + " tabIndex='1' />";
      } else if (type == "textarea") {
        str = "<textarea id='" + id + "' name='" + name + "' rows='4' cols='18'" + readonly + " tabIndex='1'></textarea>";
      } else if (type == "serial") {
        str = "<input type='hidden' id='" + id + "' name='" + name + "' />";
      } else if (type == "relationship") {
        str = "<input type='text' id='" + id + "' name='" + name + "' class='autocomplete' list='monkey.autocomplete." + property.autocomplete + "' tabIndex='1'>";
      } else {
        str = "<input type='text' name='" + name + "' id='" + id + "'" + readonly + " tabIndex='1' autocomplete='off'>";
      };
      return str;
    }
  }
};
/////////////////////////////////////////////////
//END GLOBALS////////////////////////////////////
/////////////////////////////////////////////////

(function($) {
  $.fn.visible = function(test) {
    return this.each(function() {
      if (test) { $(this).show() } else { $(this).hide() };
    });
  };
/////////////////////////////////////////////////
//ON LOAD////////////////////////////////////////
/////////////////////////////////////////////////

$(function() { $("body").append("<div id='ac_suggestion_box'></div>") });
var ac_current_input = {};
$.fn.autocomplete = function(options) {
  var defaults = {};
  var options = $.extend(defaults, options);

  var suggestion_box = $("#ac_suggestion_box");
  var selected_class = "selected";
  var tag_type = "p";
  var selected_entry_name = tag_type + "." + selected_class;

  var insert_wildcards = function(text) {
    //make it match space or period between letters
    //return text.replace(/(\S)/g, "$1(?: |\.)*");
    //make it match anything between letters
    return text.replace(/(\S)/g, "$1.*");
  };

  var match = function(input, src) {
    if (!input) return false;
    var re = new RegExp("^"+insert_wildcards(input), "gi");
    return re.exec(src);
  };
 
  var clear_suggestion_box = function() {
    suggestion_box.hide().html("");
  };

  var scroll_suggestion_box = function(entry) {
    var scrolltop = suggestion_box.attr("scrollTop");
    if (entry.offset().top < suggestion_box.offset().top) {
      suggestion_box.attr("scrollTop",
        scrolltop - (suggestion_box.offset().top - entry.offset().top + 1));
    };
    if (entry.offset().top + entry.height() >
        suggestion_box.offset().top + suggestion_box.height()) {
      var panel = entry.offset().top;
      var divtop = suggestion_box.offset().top;
      var divheight = suggestion_box.height();
      var panelheight = entry.height() + parseInt(entry.css("padding-top").replace("px", ""));
      suggestion_box.attr("scrollTop", scrolltop - (divtop - panel) - divheight + panelheight);
    };
  };

  suggestion_box.mouseover(function(e) {
    if ($(e.target).attr("tagName").toLowerCase() == tag_type) {
      $(selected_entry_name).removeClass(selected_class)
      $(e.target).addClass(selected_class)
    };
  }).mousedown(function(e) {
    if ($(e.target).attr("tagName").toLowerCase() == tag_type) {
      ac_current_input.val($(selected_entry_name).html());
      return false;
    };
  }).mouseup(function() {
    clear_suggestion_box();
  });

  return this.each(function() {
    var self = $(this);
    self.attr("autocomplete", "off");
    self.keyup(function(e) {
      if (e.shiftKey && e.ctrlKey) return true;
      
      var k = e.keyCode;
      if (k > 48 && k < 90 || k > 96 && k < 105 || k == 110 || k > 199 && k < 190 || k == 8) {
        suggestion_box
          .html("")
          .css({
            "top": self.offset().top + self.height() + 8,
            "left": self.offset().left
          });
        var str = "";
        for (i=0; i<self.list.length; i++) {
          if (match(self.val(), self.list[i])) {
            var even = "";
            if (i % 2 == 0) even = " class='ac_even'";
            str += "<"+tag_type+even+">" + self.list[i] + "</"+tag_type+">";
          };
        };
        if (str) {
          suggestion_box.html(str).show().attr("scrollTop", 0).css("zIndex", 1000000);
          $(suggestion_box.children()[0]).addClass(selected_class);
        } else {
          clear_suggestion_box();
        };
        return false;
      };
    }).keydown(function(e) {
      if (e.shiftKey && e.ctrlKey) return true;
      
      var k = e.keyCode;
      var selected_entry = $(selected_entry_name)
      if (k == 38) {
        var prev = $(selected_entry.prev());
        if (prev.attr("tagName")) {
          selected_entry.removeClass(selected_class);
          prev.addClass(selected_class);
          scroll_suggestion_box(prev);
        };
        return false;
      } else if (k == 40) {
        var next = $(selected_entry.next());
        if (next.attr("tagName")) {
          selected_entry.removeClass(selected_class);
          next.addClass(selected_class);
          scroll_suggestion_box(next);
        };
        return false;
      } else if (k == 13 || k == 9) {
        //return true if no suggestion so that we can submit the form
        if (!suggestion_box.is(":visible")) return true;
        var txt = selected_entry.html();
        if (txt) self.val(txt);
        clear_suggestion_box();
        if (k == 13) return false; //for safari
      };
    }).blur(function(e) {
      clear_suggestion_box();
    }).focus(function(e) {
      self.list = eval(self.attr("list"));
      ac_current_input = self;
    });
    //self.focus();
  });
};

$.fn.set = function(value) {
  return this.each(function() {
    var $el = $(this);
    var type = $el.attr("type");
    if (type) {
      if (type.toLowerCase() == "checkbox") {
        if (value) {
          $el.attr("checked", true);
        } else {
          $el.attr("checked", false);
        };
      } else {
        $el.val(value);        
      };        
    };
  });
};

$.fn.monkey = function(opts) {
  var options = $.extend({
    hotkeys: true, 
    upload: true
  }, opts);
    
  var prefix = options.prefix || "";
  var models = options.models || options.model;
  if (models) models = "models=" + models;

  return this.each(function() {
    var $self = $(this);
    $self.addClass("monkey");

    //Fill element with the html we need
    $self.html("<select id='monkey_select'></select> \
    <div id='monkey_table' class='table' data_model=''> \
      <div class='thead'> \
        <div class='tr'></div> \
        <form action='list' class='tr' id='monkey_filter' method='GET'></form> \
      </div> \
      <div class='tbody'></div> \
      <div class='tfoot'> \
        <a class='btn' href='#' id='add'>Add</a> \
        <a class='btn' href='#' id='copy'>Copy</a> \
        <a class='btn' href='#' id='edit'>Edit</a> \
        <a class='btn' href='#' id='edit_all'>Edit All</a> \
        <a class='btn' href='#' id='delete'>Delete</a> \
        <a class='btn' href='#' id='delete_all'>Delete All</a> \
        <a class='btn' href='#' id='excel'>Excel</a> \
        <a class='btn' href='#' id='upload'>Upload</a> \
        <span id='mid'> \
        <span id='first'><< </span><span id='previous'>< </span> \
        <span>Page <input type='text' value='1' id='offset'> of <span id='pages'></span></span> \
        <span id='next'> ></span><span id='last'> >></span> \
        <select id='limit'><option val='10'>10</option><option val='50'>50</option></select> \
        <span id='count'></span> \
        </span> \
      </div> \
    </div> \
    <form id='monkey_form' action='/update' method='post'> \
      <div id='outer'><div id='inner'></div> \
      <input type='submit' value='Update' id='update' class='form_btn'> \
      <input type='button' value='Cancel' id='cancel' class='form_btn'> \
      </div> \
    </form>");

    //Initialize the important variables
    var form_id = "#monkey_form";
    var $form = $(form_id, $self);
    var $select = $("#monkey_select", $self);
    var $table = $("#monkey_table", $self);
    var $tbody = $(".tbody", $table);
    var $limit = $("#limit", $table);
    var $offset = $("#offset", $table);
    var $count = $("#count", $table);
    var $pages = $("#pages", $table);
  
    //bind click event to navigation buttons
    $("#first", $table).click(function() { $offset.val(1).trigger("change", false) });
    $("#previous", $table).click(function() { $offset.val(parseInt(parseInt($offset.val()) - 1)).trigger("change", false) });
    $("#next", $table).click(function() { $offset.val(parseInt(parseInt($offset.val()) + 1)).trigger("change", false) });
    $("#last", $table).click(function() { $offset.val($pages.html()).trigger("change", false) });

    //bind change event to limit select tag and offset input
    $limit.bind("change", function() { $offset.val(1).trigger("change") });
    $offset.bind("change", function(e, count) {
      var curr = parseInt($offset.val());
      var last = parseInt($pages.html());
      if (curr < 1) { $offset.val(1); return false };
      if (curr > last && last != 0) { $offset.val(last); return false };
      if (!$offset.val().match(/^\d+$/)) $offset.val(1);
      $tbody.trigger("list", count);
    });
    
    //initialize the uploader button
    if (options.upload) {
      var uploader = new AjaxUpload('#upload', {
        action: prefix + '/upload',
        name: 'file',
        autoSubmit: true,
        responseType: "json",
        onComplete: function(file, response) {
          if (response.error) {
            alert(response.error)
          } else {
            alert(response.message)
            //$tbody.trigger("list", true);
          };
        }
      });
    };
  
    //bind events to tbody
    $tbody.bind("edit", function() {
      var i = parseInt($(".tr.selected", $tbody).attr("data_index"));
      var model = monkey.models[$select.val()];
      var row = model.data[i];
      $.each(row, function(key, value) {
        $(form_id + " #" + key).set(value);
      });
      $("input[type='submit']", $form).val("Update");
      $form.attr("action", "/update").show();
      $("input[type='text']:first", $form).focus().select();
    }).bind("edit_all", function() {
      var i = parseInt($(".tr.selected", $tbody).attr("data_index"));
      var model = monkey.models[$select.val()];
      var row = model.data[i];
      $.each(row, function(key, value) {
        $(form_id + " #" + key).set(value);
      });
      $("input[type='submit']", $form).val("Update All");
      $form.attr("action", "/update_all").show();
      $("input[type='text']:first", $form).focus().select();      
    }).bind("add", function() {
      $("input[type='checkbox'], input[type='text'], textarea", $form).set("");
      $("input[type='submit']", $form).val("Add");
      $("input[name='id']", $form).val("");
      $form.attr("action", "/create").show();
      $("input[type='text']:first", $form).select();
    }).bind("copy", function() {
      $tbody.trigger("edit");
      $("input[type='submit']", $form).val("Add");
      $("input[name='id']", $form).val("");
      $form.attr("action", "/create").show();
      $("input[type='text']:first", $form).select();
    }).bind("delete", function() {
      var model_name = $select.val();
      if (confirm("Are you sure you want to DELETE this " + model_name + "?")) {
        var _id = parseInt($(".tr.selected", $tbody).attr("data_id"));
        $.ajax({
          type: "DELETE",
          cache: false,
          dataType: "json",
          url: prefix + "/delete",
          data: "_id=" + _id + "&model=" + model_name,
          success: function(response) {
            if (response.error) { alert(response.error); return false };
            $tbody.trigger("list", true);
          }
        });
        return false;          
      };
    }).bind("delete_all", function() {
      var model_name = $select.val();
      if (confirm("Are you sure you want to DELETE ALL of these " + monkey.models[model_name].label.plural + "?")) {
        $.ajax({
          type: "DELETE",
          cache: false,
          dataType: "json",
          url: prefix + "/delete_all",
          data: $("#monkey_filter").serialize() + "&model=" + model_name,
          success: function(response) {
            if (response.error) { alert(response.error); return false };
            $select.trigger("change");
          }
        });
        return false;
      };
    }).bind("excel", function() {
      location.href = prefix + '/excel?model=' + $select.val() + "&" + $("#monkey_filter").serialize();
    }).bind("list", function(e, count) {
      var model_name = $select.val();
      var model = monkey.models[model_name];
      var limit = parseInt($limit.val());
      var offset = limit * (parseInt($offset.val()) - 1);
      var data = $("#monkey_filter").serialize();
      data += "&model=" + model_name + "&limit=" + limit + "&offset=" + offset + "&count=" + count;
      //Get the rows from the server        
      $.ajax({
        type: "GET",
        cache: false,
        dataType: "json",
        url: prefix + "/list",
        data: data,
        success: function(response) {
          if (response.error) { alert(response.error); return false };
          var last = parseInt(offset + limit);
          monkey.count = response.count || monkey.count;
          if (last > monkey.count) last = monkey.count;
          $count.html("View " + parseInt(offset + 1) + " - " + last + " of " + monkey.count);
          $pages.html(Math.ceil(parseInt(monkey.count) / limit));
        
          $("#first, #previous, #last, #next", $table).show();
          if ($("#offset").val() == "1") $("#first, #previous", $table).hide();
          if ($("#offset").val() == $pages.html()) $("#last, #next", $table).hide();

        
          model.data = response.rows;
          //fill the table body with rows
          var tbody = "";
          $.each(model.data, function(i, row) {
            var even = "even";
            if (i % 2 != 0) even = "";
            var tr = "<div class='tr " + even + "' data_id=" + row.id + " data_index=" + i + ">";
            $.each(model.order, function(i, property_name) {
              var property = model.properties[property_name];
              if (!property.hide_in_index) {
                tr += "<div class='td " + property_name + "'>" + row[property_name] + "</div>";
              };        
            });
            tr += "</div>";
            tbody += tr;
          });
          $tbody.html(tbody);
        
          //fit the widths of the table cells to the data
          var tds = [];
          var klasses = [];
          $("div.tr", $table).each(function(i) {
            if (i > 10) return false;
            $tr = $(this);
            $(".td", $tr).each(function(j) {
              var $td = $(this);
              if (tds[j]) {
                var width = $td.width() + 50;
                if (width > 200) width = 200;
                if (width > tds[j]) tds[j] = width;
              } else {
                tds.push($td.width());
                klasses.push($td.attr("class").replace("td ", ""));
              };
            });
          });
          var sum = 0;
          $.each(tds, function(i, width) {
            sum += width + 15;
          });
          var ratio = 1;
          if (sum > $tbody.width()) ratio = $tbody.width() / sum;
          
          $.each(klasses, function(i, klass) {
            $("." + klass).width(tds[i] * ratio);
          });

          //add events to the table rows
          $(".tr", $tbody).bind("select", function() {
            var $self = $(this);
            $self.siblings().removeClass("selected")
            $self.addClass("selected");
            //scroll the table body if necessary
            var self_top = $self.position().top;
            var tbody_top = $tbody.position().top;
            var tbody_bottom = tbody_top + $tbody.height();
            if (self_top < tbody_top) $tbody.scrollTop(self_top - $(".tr:first", $tbody).position().top);
            if (self_top > tbody_bottom) $tbody.scrollTop($tbody.scrollTop() - tbody_bottom + self_top + $self.height());
            if ($form.is(':visible')) $tbody.trigger("edit");
          }).click(function() { $(this).trigger("select") } );

          //create the form for this model
          create_form(model_name);
          $(".tr:first", $tbody).trigger("select");

          //change the title of the footer buttons
          $(".tfoot .btn#add").attr("title", "Add a new " + model.label.singular);
          $(".tfoot .btn#copy").attr("title", "Copy this " + model.label.singular);
          $(".tfoot .btn#edit").attr("title", "Edit this " + model.label.singular);
          $(".tfoot .btn#edit_all").attr("title", "Edit all of these " + model.label.plural);
          $(".tfoot .btn#delete").attr("title", "Delete this " + model.label.singular);
          $(".tfoot .btn#delete_all").attr("title", "Delete all of these " + model.label.plural);
          $(".tfoot .btn#excel").attr("title", "Download these " + model.label.plural + " to Excel");
          $(".tfoot .btn#upload").attr("title", "Upload a file of " + model.label.plural);
        
        }
      });
      return false;
    });
  
    //override the monkey_form action
    $form.submit(function() {
      var model_name = $select.val();
      var $self = $(this);
      var data = $self.serialize() + "&model=" + model_name;
      
      var action = $self.attr("action");
      if (action == "/update_all") data += "&" + $("#monkey_filter").serialize().replace(/obj/g, "filter");
      
      $.ajax({
        type: "POST",
        cache: false,
        dataType: "json",
        url: prefix + action,
        data: data,
        success: function(response) {
          if (response.error) { alert(response.error); return false };
          $tbody.trigger("list", true);
        }
      });
      return false;
    });
  

    //override footer buttons
    $(".tfoot .btn").click(function() {
      $tbody.trigger($(this).attr("id"));
      return false;
    });

    //cancel and hide the form
    $("#cancel", $form).click(function() { $form.hide() });
  
    //Create the form
    create_form = function(model_name) {
      var model = monkey.models[model_name];
      var html = "";
      var num = 0;
      $.each(model.order, function(j, property_name) {
        var property = model.properties[property_name];
        if (!property.hide || property.type == "serial") {
          if (num == 0) html += "<div class='stacked'>";
          if ((num - 1) % 5 == 0 && num != 0) html += "</div><div class='stacked'>";
          
          if (!property.hide) html += "<div>" + property.header + "</div>";
          html += monkey.partial.element(model_name, property, property_name);
          
          num += 1;
          //var required = "";
          //if (property.required) required = "Required";
          //html += "<span>" + required + "</span>";
        };
      });
      html += "</div>";
      $("#inner", $form).html(html);
      $(".autocomplete").autocomplete();
      $form.hide();
    }

    //Call init on the server and get the process started
    $.ajax({
      type: "GET",
      cache: false,
      dataType: "json",
      url: prefix + "/init",
      data: models,
      success: function(models) {
        //Fill monkey.models with data
        $.each(models, function(model_name, model) {
          if (!monkey.models[model_name]) monkey.models[model_name] = model;
        });
      
        //Fill our select tag with the models and bind the change event
        var html = "";
        $.each(models, function(model_name, model) {
          html += "<option value='" + model_name + "'>" + model.label.plural + "</option>";
        });
      
        $select.html(html).change(function() {
          var model_name = $(this).val();
          var model = monkey.models[model_name];
        
          //fill the table header with headers
          var header_row = "";
          var filter_row = "";
          var relationships = {}
          $.each(model.order, function(i, property_name) {
            var property = model.properties[property_name];
            if (!property.hide_in_index) {
              header_row += "<div class='td " + property_name + "'>" + property.header + "</div>";
              filter_row += "<div class='td " + property_name + "'>";
              filter_row += "<input type='text' name='obj[" + property.finder + "]' autocomplete='off'></div>";
            };
            if (!property.hide && property.type == "relationship") relationships[property.autocomplete] = 1;
          });
          filter_row += "<input type='submit' style='display:none;'>";
          $(".thead .tr:first", $table).html(header_row);
          $(".thead form.tr:first", $table).html(filter_row);
          
          //Enter was pressed so submit the form
          $(".thead form.tr input", $table).keydown(function(e) {
            if (e.keyCode == 13) {
              $offset.val(1).trigger("change", true);
              $(this).select();
              return false;
            };
          });

          //get autocomplete data
          rel = []
          $.each(relationships, function(name, i) { rel.push(name) });
          rel = rel.join(",");
          if (rel) {
            $.ajax({
              type: "GET",
              cache: false,
              dataType: "json",
              url: prefix + "/autocomplete",
              data: "models=" + rel,
              success: function(models) {
                monkey.autocomplete = models;
              }
            });
          };
          
          //set the uploader data to this model_name
          if (options.upload) uploader.setData({ model: model_name });
          
          //hide or show buttons and bind keystrokes based on the user's permissions
          $("#add, #copy", $table).visible(model.authorized_for_create);
          $("#edit, #edit_all", $table).visible(model.authorized_for_update);
          $("#delete, #delete_all", $table).visible(model.authorized_for_delete);
          $("#upload", $table).visible(options.upload && model.authorized_for_create && model.authorized_for_update);
          if (options.hotkeys) {
            var $doc = $(document);
            var k = "keydown";
            var fn = function() {};
            $doc.unbind(k, "ctrl+shift+a", fn);
            $doc.unbind(k, "ctrl+shift+c", fn);
            $doc.unbind(k, "ctrl+shift+e", fn);
            $doc.unbind(k, "ctrl+shift+d", fn);
            if (model.authorized_for_create) {
              $doc.bind(k, "ctrl+shift+a", function() { $tbody.trigger("add"); return false });
              $doc.bind(k, "ctrl+shift+c", function() { $tbody.trigger("copy"); return false });
            } else {
              $doc.unbind(k, "ctrl+shift+a", fn);
              $doc.unbind(k, "ctrl+shift+c", fn);
            };
            if (model.authorized_for_update) {
              $doc.bind(k, "ctrl+shift+e", function() { $tbody.trigger("edit"); return false });
            } else {
              $doc.unbind(k, "ctrl+shift+e", fn);
            };
            if (model["delete"]) {
              $doc.bind(k, "ctrl+shift+d", function() { $tbody.trigger("delete"); return false });
            } else {
              $doc.bind(k, "ctrl+shift+d", fn);
            };            
          };
          
          //get the data
          $offset.val(1).trigger("change", true);
          $(this).blur();
        });
        
        //hide the select element if there's only one model
        $select.show();
        if ($select.children().length == 1) $select.hide();
        
        //select the first model
        if (location.hash) $select.val(location.hash.replace("#", ""));
        $select.trigger("change");
      }
    });
    
    //shortcut keys
    if (options.hotkeys) {
      $(document).bind("keydown", "ctrl+shift+down", function() { $(".tr.selected", $tbody).next().trigger("select"); return false });
      $(document).bind("keydown", "ctrl+shift+up", function() { $(".tr.selected", $tbody).prev().trigger("select"); return false });
      $(document).bind("keydown", "ctrl+shift+right", function() { $("#next").click(); return false });
      $(document).bind("keydown", "ctrl+shift+left", function() { $("#previous").click(); return false });
      $(document).bind("keydown", "ctrl+shift+m", function() { $select.focus(); return false });
    };
  
  });
};
})(jQuery);
/////////////////////////////////////////////////
//END ON LOAD////////////////////////////////////
/////////////////////////////////////////////////

