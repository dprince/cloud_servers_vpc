
function server_group_selectors() {

    $("#server-group-new-link").button({
                icons: {
                    primary: 'ui-icon-circle-plus'
                }
    }
    );

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
            $("#tr-"+id).remove();
        },
        error: function(data) {
            alert('Error: Failed to delete record.');
        }
    });

   });

}
