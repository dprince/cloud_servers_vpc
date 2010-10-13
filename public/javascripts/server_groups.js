
function server_group_selectors() {

    $("#server-group-new-link").button({
                icons: {
                    primary: 'ui-icon-circle-plus'
                }
    }
    );

    $(".server-group-create").click(function(e){
         e.preventDefault();

         $.get($(this).attr("href"), function(html_snippet) {

           $("#server-group-dialog").html(
               html_snippet
           );

            $("#server-group-dialog").dialog({
                modal: true,
                height: 515,
                width: 700,
                buttons: {
                    Save: function() { create_server_group() }
                }
            });

        });
        
    });

}

function server_group_table_selectors() {

$(".servergroup-paginate a").click(function(e){
     e.preventDefault();

    globalRefreshURL=$(this).attr("href");
    globalRefreshDivId="#server_groups"

     $.get($(this).attr("href"), function(html_snippet) {

       $("#server_groups").html(
            html_snippet
       );

     });

   });

$(".server-group-delete").click(function(e){

    e.preventDefault();

    if (!confirm("Delete group?")) {
        return;
    }

    $.ajax({
        url: $(this).attr("href")+".xml",
        type: 'POST',
        data: { _method: 'delete' },
        success: function(data) {
            id=$("id", data).text();
            $("#server-group-tr-"+id).remove();
        },
        error: function(data) {
            alert('Error: Failed to delete record.');
        }
    });

   });

}

function create_server_group_add_row() {
	var count=parseInt($("#server-group-create-form-row-count").attr("value"));
	count++;
	$("#server-group-create-form-row-count").attr("value", ""+count);

	var image_opts=$("#create-server-group-table tr:nth-child(2) td:nth-child(3) select").html();
	var flavor_opts=$("#create-server-group-table tr:nth-child(2) td:nth-child(4) select").html();
	var account_id=$("#server-group-create-account-input").attr("value");

	tr_html='<tr class="tr' + count%2 + '">';
	tr_html+='<td><button class="create-server-group-delete-button">Delete</button></td>';
	tr_html+='<td><input type="text" value="" name="server_group[servers_attributes]['+count+'][name]" />';
	tr_html+='<input type="hidden" value="N/A" name="server_group[servers_attributes]['+count+'][description]" />';

	tr_html+='<input type="hidden" value="'+account_id+'" name="server_group[servers_attributes]['+count+'][account_id]" />';
	tr_html+='</td>';

	tr_html+='<td><select name="server_group[servers_attributes]['+count+'][image_id]">'+ image_opts+'</select></td>';
	tr_html+='<td><select name="server_group[servers_attributes]['+count+'][flavor_id]">'+ flavor_opts+'</select></td>';
	tr_html+='<td>&nbsp;</td>';
	tr_html+='</tr>';
	$("#create-server-group-table tr:last").after(tr_html);

    $(".create-server-group-delete-button").button({
        icons: {
            primary: 'ui-icon-circle-close'
        },
            text: false
        }
    );

    $(".create-server-group-delete-button").click(function(e){

      e.preventDefault();
      $(this).parent().parent().remove();

    });

}

function create_server_group() {


    var post_data = $("#server-group-create-form").serialize();
    $.ajax({
        url: $("#server-group-create-form").attr("action"),
        type: 'POST',
        data: post_data,
        dataType: 'html',
        success: function(data) {
            id=$("id", data).text();
			$("#server-group-dialog").html("");
            $("#server-group-dialog").dialog('close');
            $("#tabs").tabs('load', 0);
        },
        error: function(data) {
            $("#server-group-error-messages").css("display", "inline");
            err_html="<ul>";
            $(data.responseText).find("error").each (function() {
                err_html+="<li>"+$(this).text()+"</li>";
            });
            err_html+="</ul>";
            $("#server-group-error-messages-content").html(err_html);
        }
    });

}
