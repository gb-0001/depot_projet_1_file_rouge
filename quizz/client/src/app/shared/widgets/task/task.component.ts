import { Component, OnInit, Input } from '@angular/core';

@Component({
  selector: 'app-task',
  templateUrl: './task.component.html',
  styleUrls: ['./task.component.scss']
})
export class TaskComponent implements OnInit {

  @Input() title: string;
  @Input() nbr: number;
  @Input() id: number;
  @Input() update: string;
  @Input() delete: string;
  @Input() questiondata:any;

  constructor() { }

  ngOnInit() {
  }

}