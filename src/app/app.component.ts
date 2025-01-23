import { CommonModule } from '@angular/common';
import { Component, ElementRef, OnInit, ViewChild } from '@angular/core';
import {
  PoContainerModule,
  PoMenuModule,
  PoPageModule,
  PoImageModule,
  PoButtonModule,
  PoPopoverModule,
} from '@po-ui/ng-components';
import {
  ProAppConfigService,
  ProJsToAdvplService,
} from '@totvs/protheus-lib-core';
import { Free } from './types/Free';
import { Circle } from './types/Circle';
import { Line } from './types/Line';
import { Rectangle } from './types/Rectangle';
import { Oval } from './types/Oval';
import { Text } from './types/Text';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [
    CommonModule,
    PoContainerModule,
    PoPageModule,
    PoMenuModule,
    PoImageModule,
    PoButtonModule,
    PoPopoverModule,
  ],
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css'],
})
export class AppComponent implements OnInit {
  @ViewChild('canvasContainer', { read: ElementRef, static: true })
  canvasContainerRef!: ElementRef<HTMLDivElement>;
  @ViewChild('canvas', { static: true })
  canvasRef!: ElementRef<HTMLCanvasElement>;
  @ViewChild('poButtonColors', { read: ElementRef, static: true })
  poButtonColorsRef!: ElementRef<HTMLButtonElement>;
  @ViewChild('poButtonFontSize', { read: ElementRef, static: true })
  poButtonFontSizeRef!: ElementRef<HTMLButtonElement>;

  title = 'marcacao-defeito';

  private canvasContainer!: HTMLDivElement;
  private canvas!: HTMLCanvasElement;
  private ctx!: CanvasRenderingContext2D;
  private isDrawing = false;
  private isDrawInit = false;
  private currentAction!: string;
  private startX = 0;
  private startY = 0;
  private img = new Image();
  private curColor = '';
  private fontSize = 16;
  private textBoxIndexCount = 0;

  private free: Free[][] = [];
  private circles: Circle[] = [];
  private lines: Line[] = [];
  private rectangles: Rectangle[] = [];
  private ovals: Oval[] = [];
  private texts: Text[] = [];

  private actionHistory: string[] = [];

  imgWidth = 0;
  imgHeight = 0;
  errorMessage: string = '';
  hasError: boolean = false;

  menuItems = [
    {
      label: 'Livre',
      icon: 'ph ph-note-pencil',
      action: () => this.setCurrentAction('free'),
    },
    {
      label: 'Linha',
      icon: 'ph ph-line-vertical',
      action: () => this.setCurrentAction('line'),
    },
    {
      label: 'Círculo',
      icon: 'ph ph-circle',
      action: () => this.setCurrentAction('circle'),
    },
    {
      label: 'Retângulo',
      icon: 'ph ph-rectangle',
      action: () => this.setCurrentAction('rectangle'),
    },
    {
      label: 'Oval',
      icon: 'ph ph-chat-teardrop',
      action: () => this.setCurrentAction('oval'),
    },
    {
      label: 'Texto',
      icon: 'ph ph-text-aa',
      action: () => this.setCurrentAction('text'),
    },
    {
      label: 'Desfaz',
      icon: 'ph ph-arrow-u-up-left',
      action: () => this.undoAction(),
    },
    {
      label: 'Apagar',
      icon: 'ph ph-eraser',
      action: () => this.deleteContent(),
    },
    {
      label: 'Salvar',
      icon: 'ph ph-floppy-disk',
      action: () => this.saveImage(),
    },
    {
      label: 'Etiqueta',
      icon: 'ph ph-barcode',
      action: () => this.click(),
    },
  ];

  constructor(
    private proAppConfigService: ProAppConfigService,
    private proJsToAdvplService: ProJsToAdvplService
  ) {
    this.proJsToAdvplService.jsToAdvpl('receberProtheus', '');

    // if (!data) {
    //   this.throwError('Erro ao buscar os dados.');

    //   setTimeout(() => this.closeApp(), 5000);
    // }

    // const pairs = data.split('|');
    // const result = Object.fromEntries(pairs.map((pair) => pair.split('=')));
    // console.log(result);
  }

  click() {
    alert('pedro teste');

    this.proJsToAdvplService.jsToAdvpl('receberProtheus', '');

    alert(this.proJsToAdvplService.jsToAdvpl('receberProtheus', ''));
  }

  ngOnInit() {
    this.canvasContainer = this.canvasContainerRef.nativeElement;
    this.canvas = this.canvasRef.nativeElement;
    this.ctx = this.canvas.getContext('2d')!;

    this.loadImage();
  }

  private loadImage() {
    this.img.src = 'matriz.bmp';

    this.img.onload = () => {
      this.imgWidth = this.img.width;
      this.imgHeight = this.img.height;

      this.ctx.drawImage(this.img, 0, 0);
    };
  }

  setCurrentAction(currentAction: string) {
    this.currentAction = currentAction;

    const crosshairActions = ['free', 'line', 'circle', 'rectangle', 'oval'];

    if (crosshairActions.includes(currentAction)) {
      this.canvasRef.nativeElement.style.cursor = 'crosshair';
    } else if (currentAction === 'text') {
      this.canvasRef.nativeElement.style.cursor = 'text';
    } else {
      this.canvasRef.nativeElement.style.cursor = 'default';
    }
  }

  startDrawing(event: MouseEvent) {
    if (!this.currentAction) return;

    this.isDrawing = true;

    this.ctx.strokeStyle = this.curColor || 'black';

    this.startX = event.offsetX;
    this.startY = event.offsetY;

    if (this.currentAction === 'free') {
      this.startFreeDrawing(event);
    }

    if (this.currentAction === 'text') {
      this.isDrawing = false;
      this.typeText();
    }
  }

  private startFreeDrawing(event: MouseEvent) {
    const curMousePositionX = event.offsetX;
    const curMousePositionY = event.offsetY;

    this.ctx.beginPath();
    this.ctx.moveTo(curMousePositionX, curMousePositionY);
    this.free.push([
      { x: curMousePositionX, y: curMousePositionY, color: this.curColor },
    ]);
  }

  draw(event: MouseEvent) {
    if (!this.isDrawing) return;

    if (this.currentAction !== 'free') this.redrawCanvas();

    const actionHandlers: Record<string, (x: number, y: number) => void> = {
      free: this.freeDraw.bind(this),
      line: this.drawLine.bind(this),
      circle: this.drawCircle.bind(this),
      rectangle: this.drawRectangle.bind(this),
      oval: this.drawOval.bind(this),
    };

    const handler = actionHandlers[this.currentAction];

    if (handler) {
      const curMousePositionX = event.offsetX;
      const curMousePositionY = event.offsetY;

      handler(curMousePositionX, curMousePositionY);
    }
  }

  stopDrawing(event: MouseEvent) {
    if (!this.isDrawing) return;

    const actionHandlers: Record<string, (x: number, y: number) => void> = {
      line: this.stopLineDrawing.bind(this),
      circle: this.stopCircleDrawing.bind(this),
      rectangle: this.stopRectangleDrawing.bind(this),
      oval: this.stopOvalDrawing.bind(this),
    };

    const handler = actionHandlers[this.currentAction];

    if (handler) {
      const curMousePositionX = event.offsetX;
      const curMousePositionY = event.offsetY;

      handler(curMousePositionX, curMousePositionY);
    }

    if (!this.isDrawInit) this.isDrawInit = true;
    if (this.currentAction.length) this.actionHistory.push(this.currentAction);
    this.isDrawing = false;
  }

  private freeDraw(curMousePositionX: number, curMousePositionY: number) {
    if (!this.free.length) return;

    const lastIndex = this.free.length - 1;

    this.free[lastIndex].push({
      x: curMousePositionX,
      y: curMousePositionY,
      color: this.curColor,
    });
    this.ctx.lineTo(curMousePositionX, curMousePositionY);
    this.ctx.stroke();
  }

  private drawLine(curMousePositionX: number, curMousePositionY: number) {
    // Desenha a linha temporária para visualização
    this.ctx.beginPath();
    this.ctx.moveTo(this.startX, this.startY);
    this.ctx.lineTo(curMousePositionX, curMousePositionY);

    this.ctx.strokeStyle = this.curColor || 'black';
    this.ctx.stroke();
  }

  private drawCircle(curMousePositionX: number, curMousePositionY: number) {
    const radius = Math.sqrt(
      Math.pow(curMousePositionX - this.startX, 2) +
        Math.pow(curMousePositionY - this.startY, 2)
    );

    // Desenha o círculo temporário para visualização
    this.ctx.beginPath();
    this.ctx.arc(this.startX, this.startY, radius, 0, 2 * Math.PI);

    this.ctx.strokeStyle = this.curColor || 'black';
    this.ctx.stroke();
  }

  private drawRectangle(curMousePositionX: number, curMousePositionY: number) {
    const width = curMousePositionX - this.startX;
    const height = curMousePositionY - this.startY;

    // Desenha o retângulo temporário para visualização
    this.ctx.beginPath();
    this.ctx.rect(this.startX, this.startY, width, height);

    this.ctx.strokeStyle = this.curColor || 'black';
    this.ctx.stroke();
  }

  private drawOval(curMousePositionX: number, curMousePositionY: number) {
    const radiusX = Math.abs(curMousePositionX - this.startX) / 2;
    const radiusY = Math.abs(curMousePositionY - this.startY) / 2;
    const centerX =
      this.startX + (curMousePositionX > this.startX ? radiusX : -radiusX);
    const centerY =
      this.startY + (curMousePositionY > this.startY ? radiusY : -radiusY);

    // Desenha a oval temporária para visualização
    this.ctx.beginPath();
    this.ctx.ellipse(centerX, centerY, radiusX, radiusY, 0, 0, 2 * Math.PI);

    this.ctx.strokeStyle = this.curColor || 'black';
    this.ctx.stroke();
  }

  private redrawCanvas() {
    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
    this.ctx.drawImage(this.img, 0, 0);

    this.redrawFree();
    this.redrawCircles();
    this.redrawLines();
    this.redrawRectangles();
    this.redrawOvals();
  }

  private redrawFree() {
    if (!this.free.length) return;

    this.free.forEach((free) => {
      if (free.length > 1) {
        this.ctx.beginPath();
        this.ctx.moveTo(free[0].x, free[0].y);

        free.forEach((point, index) => {
          if (index !== 0) {
            this.ctx.lineTo(point.x, point.y);
          }
        });

        this.ctx.strokeStyle = free[0].color || 'black';
        this.ctx.stroke();
      }
    });
  }

  private redrawLines() {
    if (!this.lines.length) return;

    this.lines.forEach((line) => {
      this.ctx.beginPath();
      this.ctx.moveTo(line.startX, line.startY);
      this.ctx.lineTo(line.endX, line.endY);

      this.ctx.strokeStyle = line.color || 'black';
      this.ctx.stroke();
    });
  }

  private redrawCircles() {
    if (!this.circles.length) return;

    this.circles.forEach((circle) => {
      this.ctx.beginPath();
      this.ctx.arc(circle.x, circle.y, circle.radius, 0, 2 * Math.PI);

      this.ctx.strokeStyle = circle.color || 'black';
      this.ctx.stroke();
    });
  }

  private redrawRectangles() {
    if (!this.rectangles.length) return;

    this.rectangles.forEach((rect) => {
      this.ctx.beginPath();
      this.ctx.rect(rect.x, rect.y, rect.width, rect.height);

      this.ctx.strokeStyle = rect.color || 'black';
      this.ctx.stroke();
    });
  }

  private redrawOvals() {
    if (!this.ovals.length) return;

    this.ovals.forEach((oval) => {
      this.ctx.beginPath();
      this.ctx.ellipse(
        oval.x,
        oval.y,
        oval.radiusX,
        oval.radiusY,
        0,
        0,
        2 * Math.PI
      );

      this.ctx.strokeStyle = oval.color || 'black';
      this.ctx.stroke();
    });
  }

  private stopLineDrawing(
    curMousePositionX: number,
    curMousePositionY: number
  ) {
    // Add last line drown
    this.lines.push({
      startX: this.startX,
      startY: this.startY,
      endX: curMousePositionX,
      endY: curMousePositionY,
      color: this.curColor,
    });
  }

  private stopCircleDrawing(
    curMousePositionX: number,
    curMousePositionY: number
  ) {
    // Calc last circle drown
    const radius = Math.sqrt(
      Math.pow(curMousePositionX - this.startX, 2) +
        Math.pow(curMousePositionY - this.startY, 2)
    );

    // Add last circle drown
    this.circles.push({
      x: this.startX,
      y: this.startY,
      radius,
      color: this.curColor,
    });
  }

  private stopRectangleDrawing(
    curMousePositionX: number,
    curMousePositionY: number
  ) {
    // Calc last rectangle drown
    const width = curMousePositionX - this.startX;
    const height = curMousePositionY - this.startY;

    // Add last rectangle drown
    this.rectangles.push({
      x: this.startX,
      y: this.startY,
      width,
      height,
      color: this.curColor,
    });
  }

  private stopOvalDrawing(
    curMousePositionX: number,
    curMousePositionY: number
  ) {
    // Calc last oval drown
    const radiusX = Math.abs(curMousePositionX - this.startX) / 2;
    const radiusY = Math.abs(curMousePositionY - this.startY) / 2;
    const centerX =
      this.startX + (curMousePositionX > this.startX ? radiusX : -radiusX);
    const centerY =
      this.startY + (curMousePositionY > this.startY ? radiusY : -radiusY);

    // Add last oval drown
    this.ovals.push({
      x: centerX,
      y: centerY,
      radiusX,
      radiusY,
      color: this.curColor,
    });
  }

  private typeText() {
    const editableBox = this.createEditableDiv();

    editableBox.addEventListener('blur', () =>
      this.toggleTextToArray(editableBox)
    );
  }

  private createEditableDiv() {
    const container = this.canvasContainerRef.nativeElement;
    const rect = this.canvas.getBoundingClientRect();
    const editableDiv = document.createElement('div');

    Object.assign(editableDiv.style, {
      position: 'absolute',
      left: `${this.startX + rect.left}px`,
      top: `${this.startY + rect.top}px`,
      border: 'none',
      background: 'transparent',
      resize: 'none',
      padding: '10px',
      cursor: 'move',
      color: this.curColor,
      fontSize: `${this.fontSize}px`,
      fontWeight: 'bold',
      overflow: 'auto',
    });

    editableDiv.contentEditable = 'true';
    container.appendChild(editableDiv);

    setTimeout(() => editableDiv.focus(), 0);

    const adjustSelectedText = () => {
      const selection = window.getSelection();
      const span = document.createElement('span');
      const newRange = document.createRange();

      if (!selection || selection.rangeCount === 0) return;

      const range = selection.getRangeAt(0);

      // Aplica estilos ao texto selecionado
      span.style.fontSize = `${this.fontSize}px`;
      span.style.color = this.curColor;
      span.appendChild(range.extractContents());
      range.insertNode(span);

      // Ajusta o cursor após a inserção
      selection.removeAllRanges();
      newRange.setStartAfter(span);
      selection.addRange(newRange);
    };

    editableDiv.addEventListener('mouseup', adjustSelectedText);

    return editableDiv;
  }

  private toggleTextToArray(textBox: HTMLDivElement) {
    const text = textBox.textContent;
    const existIndex = textBox.getAttribute('data-index');

    if (!text) {
      this.canvasContainer.removeChild(textBox);
      return;
    }

    if (!existIndex) {
      const curIndex = this.textBoxIndexCount + 1;
      textBox.setAttribute('data-index', curIndex.toString());

      this.texts.push({
        text,
        index: curIndex,
        color: this.curColor,
      });
      this.actionHistory.push('text');
      this.textBoxIndexCount++;
    } else {
      const index = parseInt(existIndex, 10);
      const existTextIndex = this.texts.findIndex(
        (item) => item.index === index
      );

      if (existTextIndex !== -1) {
        this.texts[existTextIndex].text = text;
      }
    }
  }

  setFontSize(fontSize: number) {
    this.fontSize = fontSize;
  }

  setCurrentColor(color: string) {
    this.curColor = color;
  }

  private undoAction() {
    if (!this.actionHistory.length) return;

    const lastAction = this.actionHistory[this.actionHistory.length - 1];

    if (!lastAction)
      this.throwError('Não existem mais ações para serem desfeitas');

    const actionHandlers: Record<string, () => void> = {
      free: () => this.free.pop(),
      circle: () => this.circles.pop(),
      line: () => this.lines.pop(),
      rectangle: () => this.rectangles.pop(),
      oval: () => this.ovals.pop(),
      text: () => this.removeLastTextFromArray(),
    };

    const handler = actionHandlers[lastAction];

    if (handler) {
      handler();
    }

    this.actionHistory.pop();
    this.redrawCanvas();
  }

  private removeLastTextFromArray() {
    const lastIndex =
      this.texts.length > 0 ? this.texts[this.texts.length - 1].index : -1;
    const editableDiv = this.canvasContainer.querySelector(
      `div[data-index='${lastIndex}']`
    );

    if (editableDiv) {
      this.texts.pop();
      this.canvasContainer.removeChild(editableDiv);
    }
  }

  private deleteContent() {
    this.free = [];
    this.circles = [];
    this.lines = [];
    this.rectangles = [];
    this.ovals = [];
    this.texts = [];
    this.actionHistory = [];

    this.redrawCanvas();
  }

  private saveImage() {
    // if (!this.isDrawInit) {
    //   this.throwError('Insira alguma marcação primeiro.');
    //   return;
    // }

    try {
    } catch (error) {
      console.error(error);
    }
  }

  private throwError(message: string): void {
    this.errorMessage = message;
    this.hasError = true;
  }

  private clearError(): void {
    this.errorMessage = '';
    this.hasError = false;
  }

  closeApp() {
    if (this.proAppConfigService.insideProtheus()) {
      this.proAppConfigService.callAppClose();
    } else {
      alert('O App não está sendo executado dentro do Protheus.');
    }
  }
}
