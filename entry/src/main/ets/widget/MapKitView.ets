import { MapComponent } from '@kit.MapKit';

/**
 * MapKitView — Native HarmonyOS Map Kit component.
 * Real map tiles, pinch-zoom, pan, markers.
 */
@Component
export struct MapKitView {
  @Prop centerLat: number = 39.9;
  @Prop centerLng: number = 116.4;
  @Prop zoom: number = 15;
  @Prop markers: Array<MapMarker> = [];

  private mapCtrl: Object | null = null;
  private ready: boolean = false;

  private syncMap(): void {
    if (!this.ready || this.mapCtrl === null) {
      return;
    }
    const ctrl: Record<string, Function> = this.mapCtrl as Record<string, Function>;
    const target: LatLng = { latitude: this.centerLat, longitude: this.centerLng };
    const cam: CameraPosition = { target: target, zoom: this.zoom };
    ctrl['setCameraPosition'](cam);
    ctrl['clear']();
    for (const m of this.markers) {
      const pos: LatLng = { latitude: m.latitude, longitude: m.longitude };
      const icon: MarkerIcon = {
        uri: m.color === '#FF9500' ? 'rawfile://marker_teacher.png' : 'rawfile://marker_student.png'
      };
      const opt: MarkerOption = { position: pos, title: m.label, icon: icon };
      ctrl['addMarker'](opt);
    }
  }

  aboutToUpdate(): void {
    if (this.ready) {
      this.syncMap();
    }
  }

  build() {
    MapComponent({
      mapOptions: {
        position: { target: { latitude: this.centerLat, longitude: this.centerLng }, zoom: this.zoom },
        mapType: 1
      },
      mapCallback: (err: Error, controller: Object) => {
        if (err || !controller) { return; }
        this.mapCtrl = controller;
        this.ready = true;
        this.syncMap();
      }
    })
      .width('100%')
      .height('100%')
  }
}

// === Parameter types for controller method calls ===

interface LatLng {
  latitude: number;
  longitude: number;
}

interface CameraPosition {
  target: LatLng;
  zoom: number;
}

interface MarkerIcon {
  uri: string;
}

interface MarkerOption {
  position: LatLng;
  title: string;
  icon: MarkerIcon;
}

export interface MapMarker {
  latitude: number;
  longitude: number;
  label: string;
  color: string;
}
