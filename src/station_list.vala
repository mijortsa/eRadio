public class Radio.StationList : Gtk.TreeView {

    private Gtk.ListStore   list_source;
    private Radio.Stations  stations_db;
    private Gtk.Menu        context_menu;

    public signal void activated(Radio.Station station);

    public StationList () throws Radio.Error {
        this.list_source = new Gtk.ListStore (4,typeof(string),typeof(string),typeof(string),typeof(int));
        this.set_model(this.list_source);

        var cell = new Gtk.CellRendererText ();
        this.insert_column_with_attributes (-1, "Station", cell, "text", 0);
        this.insert_column_with_attributes (-1, "Genre", cell, "text", 1);
        this.insert_column_with_attributes (-1, "Url", cell, "text", 2);

        context_menu = new Gtk.Menu ();
        context_menu.add (new Gtk.MenuItem.with_label ("Edit"));
        context_menu.add (new Gtk.MenuItem.with_label ("Remove"));
        context_menu.show_all ();

        this.row_activated.connect (this.row_double_clicked);
        this.button_release_event.connect (this.open_context_menu);

        // Get Directory paths
        var home_dir = File.new_for_path (Environment.get_home_dir ());
        var radio_dir = home_dir.get_child(".local").get_child("share").get_child("radio");
        var db_file = radio_dir.get_child("stations.db");

        try {
            this.stations_db = new Radio.Stations.with_db_file (db_file.get_path());
        } catch (Radio.Error e) {
            throw e;
        }

        this.reload_list ();
    }

    public int count () {

        var num_stations = 0;
        try {
            num_stations = stations_db.count ();
        } catch (Radio.Error e) {
            stderr.printf (e.message);
        }

        return num_stations;
    }

    // Seted this as public so we can simulate station selection from window
    public void row_double_clicked() {

        Gtk.TreeIter iter;
        Gtk.TreeModel model;

        var tree_selection = this.get_selection();

        if(tree_selection == null) {
            stderr.printf("Could not get TreeSelection");
        } else {
            // Get selection id
            GLib.Value val;
            tree_selection.get_selected(out model,out iter);
            model.get_value(iter,3,out val);

            // Get station object
            var filters = new Gee.HashMap<string,string>();
            filters["id"] = "%d".printf(val.get_int());
            Gee.ArrayList<Radio.Station> station_list;

            try {
                station_list = stations_db.get(filters);

                if (station_list.size == 1) {
                    Station station = station_list[0];
                    this.activated (station);
                }
                else {
                    throw new Radio.Error.GENERAL (
                        "Model returned more or less values than one - Possible Duplicate Entry or wrong entry request");
                }
            } catch (Radio.Error e) {
                stderr.printf(e.message);
            }
        }
    }

    private bool open_context_menu (Gdk.EventButton event) {
        if(event.button == 3) {
            Gtk.TreePath path;
            var row_exists = this.get_path_at_pos((int)event.x,(int)event.y,
                                                        out path,null,null,null);
            if (row_exists) {
                this.context_menu.popup (null,null,null,event.button,event.time);
            }
        }
        return true;
    }
    // -------------- TreeView & ListStore Methods ------------ //


    private void reload_list () {
        this.clear_list ();

        Gee.ArrayList<Radio.Station> stations;
        try {
            stations = stations_db.get_all ();

            foreach (Radio.Station station in stations) {
                this.add_row (station);
            }

        } catch (Radio.Error e) {
            stderr.printf(e.message);
        }
    }

    private void add_row (Radio.Station station) {
        Gtk.TreeIter iter;
        list_source.append(out iter);
        list_source.set_value(iter,0,station.name);
        list_source.set_value(iter,1,station.genre);
        list_source.set_value(iter,2,station.url);
        list_source.set_value(iter,3,station.id);
    }

    private void clear_list () {
        list_source.clear ();
    }

}