import { Component, OnInit, Input } from '@angular/core';

@Component({
  selector: 'app-stat',
  templateUrl: './stat.component.html',
  styleUrls: ['./stat.component.scss']
})

export class StatComponent implements OnInit {

  @Input() title: string;
  @Input() value: number;
  @Input() qnbr: number;
  @Input() icon: string;
  @Input() color: string;
  @Input() update: string;
  @Input() delete: string;
  @Input() qcmdata: any;

  constructor() { }

  ngOnInit() {
  }

}
